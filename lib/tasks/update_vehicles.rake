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
            closeRoutes = Array.new

            for route in routes
              distance = route.distanceTo(update.latitude, update.longitude) * 10000

              if distance < 3
                closeRoutes << route
              end
            end

            if closeRoutes.length > 1
              # do nothing
            elsif closeRoutes.length == 1
              closeRoute = closeRoutes.first
              if (closeRoute.distanceTo(update.latitude, update.longitude) * 10000 < 1)
                vehicle.route = closeRoutes.first
                closeRoutes.first.vehicles << vehicle
              end
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
    puts "Finished at @ #{DateTime.current()}"
  end
end
