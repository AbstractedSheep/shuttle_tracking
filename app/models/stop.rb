class Stop < ActiveRecord::Base
  # Callbacks
  before_save :convert_short_name

  # Relations
  has_and_belongs_to_many :routes
  has_many :etas
  has_many :preceding_coords, :dependent => :delete_all
  
  # Validations
  validates :name, :presence => true
  validates :short_name, :presence => true, :uniqueness => true
  validates :longitude, :numericality => true, :inclusion => { :in => -180..180 }
  validates :latitude, :numericality => true, :inclusion => { :in => -90..90}
 
  # Scopes, so I don't have to type so much.
  scope :enabled, where(:enabled => true)
  scope :disabled, where(:enabled => false)

  # I prefer to use the short name instead of the ID.
  def to_param
    short_name
  end

  # Convert the short-name to a parameter, which in
  # this case tolerates [A-z0-9\-]
  def convert_short_name
    self.short_name = self.short_name.parameterize
    true # So the save doesn't give up?
  end

  def save
    super
    calculate_preceding_for_all
  end

  def update_attributes(attributes)
    super(attributes)
    calculate_preceding_for_all
  end

  def calculate_preceding_for_all
    preceding_coords.delete_all
    for route in routes.all
      calculate_preceding(route)
    end
  end

  def calculate_preceding(route)
    shortest_dist = 10000
    preceding_coord = nil
    all_coords = route.coords.all

    # Search for the closest route segment to this stop
    for i in (0..(all_coords.length-1))
      if (i == 0)
        c1 = all_coords[all_coords.length - 1]
      else
        c1 = all_coords[i - 1]
      end

      c2 = all_coords[i]

      temp_shortest_dist = point_line_distance(self.latitude, self.longitude, c1.latitude, c1.longitude, c2.latitude, c2.longitude)
      if (temp_shortest_dist < shortest_dist)
        shortest_dist = temp_shortest_dist
        preceding_coord = c1
      end
    end

    # Add or update the preceding coordinate for the route
    pc = preceding_coords.where(:route_id=>route).first
    if (pc == nil)
      PrecedingCoord.new(
          :coord => preceding_coord,
          :stop => self,
          :route => route
      ).save
    else
      pc.update_attributes(:coord => preceding_coord)
    end
  end

  def point_line_distance(lat, lon, ep1lat, ep1lon, ep2lat, ep2lon)
    ((ep2lat - ep1lat)*(ep2lon - lon) - (ep1lat - lat)*(ep2lon - ep1lon)).abs /
              Math.sqrt((ep2lat - ep1lat)**2 + (ep2lon - ep1lon)**2)
  end

end
