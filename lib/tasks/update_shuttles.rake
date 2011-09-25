require "net/http"
require 'uri'
require "json"

def pull_update
namespace :update_shuttles do
  desc "Update vehicle locations via JSON from external server"
  task :update => :environment do
    url = URI.parse("http://shuttles.rpi.edu/vehicles/current.js")
    result = Net::HTTP.get(url)
    
    @jsonVehicles = result.body.from_json

    for newVehicle in @jsonVehicles
      vehicle = Vehicle.where(:identifier => newVehicle.identifier).first
      if !vehicle.nil?
        # Time to see if the update is actually from the future.
        # And by that I mean, check if this update is represents
        # new data (i.e has a timestamp > the old data)
        last_update = vehicle.updates.latest.first
        if last_update.nil? || last_update.timestamp < timestamp
          # Actually build an update
          update = vehicle.updates.new(
            :latitude => newVehicle.latitude,
            :longitude => newVehicle.longitude,
            :heading => newVehicle.heading,
            :speed => newVehicle.speed,
            #:lock => $6.to_i,
            #:status_code => $7.to_s,
            :timestamp => newVehicle.timestamp
          )
          if update.save
            puts "Updated #{vehicle.name}"
          else
            #Debug why the update isn't valid
            update.errors.full_messages.each do |msg|
              puts msg
            end
          end
        else
         puts "No Change #{vehicle.name}."
        end
      else
        newVehicle.save
        #puts "No vehicle with ID #{$1}."
      end
    end
  end
  puts "Finished at @ #{DateTime.current()}"
end
