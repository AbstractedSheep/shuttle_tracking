require "net/http"
require 'uri'

namespace :update_vehicles do
  desc "Update vehicle locations via JSON from external server"
  task :update_json => :environment do
    url = URI.parse("http://shuttles.rpi.edu/vehicles/current.js")
    result = Net::HTTP.get(url)
    
    jsonVehicles = JSON.parse(result)

    for vehicleJson in jsonVehicles
      newVehicle = vehicleJson['vehicle']
      vehicleUpdate = newVehicle['latest_position']
      vehicle = Vehicle.where(:name => newVehicle['name']).first
      if !vehicle.nil?
        # Time to see if the update is actually from the future.
        # And by that I mean, check if this update is represents
        # new data (i.e has a timestamp > the old data)
        last_update = vehicle.updates.latest.first
        timestamp = Time.zone.parse(vehicleUpdate['timestamp'])
        if last_update.nil? || last_update.timestamp < timestamp
          # Actually build an update
          update = vehicle.updates.new(
            :latitude => vehicleUpdate['latitude'],
            :longitude => vehicleUpdate['longitude'],
            :heading => vehicleUpdate['heading'],
            :speed => vehicleUpdate['speed'],
            :timestamp => timestamp
            # Lock and status code are currently not provided via json
          )
          if update.save
            puts "Updated #{vehicle.name}"

            routes = Route.all
            closest_route = nil
            shortest_distance = 1

            for route in routes
              distance = route.distance_to(update.latitude, update.longitude) * 10000
              if distance < shortest_distance
                closest_route = route
                shortest_distance = distance
              end
            end

            if !closest_route.nil?
              puts "Setting closest route as " + closest_route.name
              vehicle.update_attributes(:route=>closest_route)
            else
              # there aren't any close routes
              if !vehicle.route.nil?
                # find and remove vehicle from associated route
                vehicle.route.vehicles.delete(vehicle)
              end

              vehicle.route = nil
            end
          else
            # Debug why the update isn't valid
            update.errors.full_messages.each do |msg|
              puts msg
            end
          end
        else
         puts "No Change #{vehicle.name}."
        end
      else
        # Consider just adding a vehicle, if it is not already present
        #newVehicle.save
        puts "No vehicle with name #{newVehicle['name']}."
      end
    end

    # ETA Calculation
    for vehicle in Vehicle.all
      if vehicle.route != nil
        vehicle_preceding = vehicle.calculate_preceding
        distance = 0
        for stop in vehicle.route.stops.all
          # This is not the right way to do this, but Rails does not like find(:route=>vehicle.route) for some reason
          stop_preceding = stop.preceding_coords.find(:all, :conditions => {:route_id=>vehicle.route}).first.coord
          # If the shuttle and stop are on the same route segment, and the shuttle has not passed the stop
          # then the total distance to travel is simply the straight-line distance from the shuttle to the stop
          if (vehicle_preceding == stop_preceding && is_before_stop(vehicle, stop, vehicle_preceding))
            distance = point_point_distance(vehicle.latest_position.latitude, vehicle.latest_position.longitude,
                                            stop.latitude, stop.longitude)
          else
            route_coords = vehicle.route.coords.all
            loc = find_in_array(route_coords, vehicle_preceding)
            loc += 1
            if (loc == route_coords.length)
              loc = 0
            end

            distance = point_point_distance(vehicle.latest_position.latitude, vehicle.latest_position.longitude,
                                              route_coords[loc].latitude, route_coords[loc].longitude)

            while (route_coords[loc] != stop_preceding)
              next_loc = loc + 1
              if (next_loc == route_coords.length)
                next_loc = 0
              end
              distance += point_point_distance(route_coords[loc].latitude, route_coords[loc].longitude,
                                              route_coords[next_loc].latitude, route_coords[next_loc].longitude)
              loc += 1
              if (loc == route_coords.length)
                loc = 0
              end
            end

            distance += point_point_distance(route_coords[loc].latitude, route_coords[loc].longitude,
                                            stop.latitude, stop.longitude)
            eta = distance / vehicle.latest_position.speed
            eta = Time.now + eta * 60 * 60
            Eta.new(
                :stop => stop,
                :vehicle => vehicle,
                :timestamp => eta
            )
            puts "New ETA: " + vehicle.name + " " + stop.name + " " + eta.to_s
          end
        end
      end
    end

    for e in Eta.all
      puts e.vehicle.name + " " + e.stop.name + " " + e.timestamp.to_s
    end

    puts "Finished at @ #{DateTime.current()}"
  end

  def is_before_stop(vehicle, stop, preceding_coord)
    lat_change1 = stop.latitude - preceding_coord.latitude
    lat_change1 = lat_change1 / lat_change1.abs
    lon_change1 = stop.longitude - preceding_coord.longitude
    lon_change1 = lon_change1 / lon_change1.abs
    lat_change2 = stop.latitude - vehicle.latest_position.latitude
    lat_change2 = lat_change2 / lat_change2.abs
    lon_change2 = stop.longitude - vehicle.latest_position.longitude
    lon_change2 = lon_change2 / lon_change2.abs

    lat_change1 == lat_change2 && lon_change1 == lon_change2
  end

  class Numeric
    def degrees
      self * Math::PI / 180
    end
  end

  # Returns the distance between two coordinates in miles
  def point_point_distance(lat1, lon1, lat2, lon2)
    earth_radius = 3956; # Miles
    dlong = (lon2 - lon1).degrees
    dlat = (lat2 - lat1).degrees

    a = Math.sin(dlat / 2)**2 +
              Math.sin(dlong / 2)**2 * Math.cos(lat1.degrees) * Math.cos(lat2.degrees)
    b = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    earth_radius * b
  end

  def find_in_array(array, search)
    for i in (0..(array.length - 1))
      if (search == array[i])
        return i
      end
    end

    -1
  end
end
