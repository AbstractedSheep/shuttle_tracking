class Vehicle < ActiveRecord::Base

  # Relations
  has_many :updates, :dependent => :destroy
  has_many :etas
  has_one :latest_position, :class_name => 'Update'
  belongs_to :route
  belongs_to :icon

  # Validations
  validates :name, :presence => true
  validates :identifier, :uniqueness => true, :allow_nil => true
  
  # Identify all the vehicles that are active AND enabled.
  # Probably useful to show these on a map.
  def self.active
    vehicles = where(:enabled => true)
    vehicles.delete_if { |v| !v.active? }
  end

  # Is the vehicle is considered active or not?
  # This can be overridden with the active_override flag,
  # but it defaults to detect motion within 3 minutes.
  def active?(threshold = ACTIVE_TIMEOUT)
    active_override? || (offline_for <= threshold)
  end

  # Compute how long it has been since the vehicle last moved.
  # Returns number of seconds or Infinity
  def offline_for
    if latest_position.nil?
      1/0.0 #Aka Infinity
    else
    (Time.now - latest_position.timestamp)
    end
  end

  def calculate_preceding
    shortest_dist = 10000
    preceding_coord = nil
    all_coords = route.coords.all

    # Search for the closest route segment to this stop
    for i in (0..(all_coords.length - 1))
      if (i == 0)
        c1 = route.coords[all_coords.length - 1]
      else
        c1 = route.coords[i - 1]
      end

      c2 = route.coords[i]

      temp_shortest_dist = point_line_distance(latest_position.latitude, latest_position.longitude, c1.latitude, c1.longitude, c2.latitude, c2.longitude)
      if (temp_shortest_dist < shortest_dist)
        shortest_dist = temp_shortest_dist
        preceding_coord = c1
      end
    end

    preceding_coord
  end

  def point_line_distance(lat, lon, ep1lat, ep1lon, ep2lat, ep2lon)
    ((ep2lat - ep1lat)*(ep2lon - lon) - (ep1lat - lat)*(ep2lon - ep1lon)).abs /
              Math.sqrt((ep2lat - ep1lat)**2 + (ep2lon - ep1lon)**2)
  end

end
