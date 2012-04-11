require 'point3d'

class Route < ActiveRecord::Base

  # Relations
  has_and_belongs_to_many :stops
  has_many :vehicles
  has_many :coords, :dependent => :destroy
  has_many :preceding_coords, :dependent => :delete_all
  
  # Validations
  validates :name, :presence => true
  validates :width, :numericality => { :greater_than_or_equal_to => 0 }

  # Scopes, so I don't have to type so much.
  scope :enabled, where(:enabled => true)
  scope :disabled, where(:enabled => false)

  accepts_nested_attributes_for :coords, :allow_destroy => true

  def distance_to(latitude, longitude)
    shortest_distance = 1000
    endpoint1 = nil

    for endpoint2 in coords
      if !endpoint1.nil?
        new_dist = point_line_dist(latitude, longitude, endpoint1.latitude, endpoint1.longitude, endpoint2.latitude, endpoint2.longitude)

        if new_dist < shortest_distance
          shortest_distance = new_dist
        end
      end

      endpoint1 = endpoint2
    end

    shortest_distance
  end

  def point_point_dist(lat1, lon1, lat2, lon2)
    r = 3956
    dlat = to_rad(lat2 - lat1)
    dlon = to_rad(lon2 - lon1)
    lat1r = to_rad(lat1)
    lat2r = to_rad(lat2)

    a = Math.sin(dlat / 2) ** 2 + Math.sin(dlon / 2) ** 2 * Math.cos(lat1r) * Math.cos(lat2r)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    r * c
  end

  def point_line_dist(lat, lon, ep1lat, ep1lon, ep2lat, ep2lon)
    r = 3956
    ep1cart = Point3D.new
    ep1cart.x = r * Math.cos(ep1lat.degrees) * Math.cos(ep1lon.degrees)
    ep1cart.y = r * Math.cos(ep1lat.degrees) * Math.sin(ep1lon.degrees)
    ep1cart.z = r * Math.sin(ep1lat.degrees)
    ep2cart = Point3D.new
    ep2cart.x = r * Math.cos(ep2lat.degrees) * Math.cos(ep2lon.degrees)
    ep2cart.y = r * Math.cos(ep2lat.degrees) * Math.sin(ep2lon.degrees)
    ep2cart.z = r * Math.sin(ep2lat.degrees)
    ptcart = Point3D.new
    ptcart.x = r * Math.cos(lat.degrees) * Math.cos(lon.degrees)
    ptcart.y = r * Math.cos(lat.degrees) * Math.sin(lon.degrees)
    ptcart.z = r * Math.sin(lat.degrees)
    origin = Point3D.new
    origin.x = 0
    origin.y = 0
    origin.z = 0

    d = ptcart.minus(ep1cart).cross_product(ptcart.minus(ep2cart)).magnitude()
    d = d / ep2cart.minus(ep1cart).magnitude()
    hypotenuse = ptcart.distance_to(ep1cart)
    theta = Math.asin(d / hypotenuse)
    adjacent = d / Math.tan(theta)

    closestcart = ep1cart.move_towards(ep2cart, adjacent)
    surfacecart = origin.move_towards(closestcart, r)

    clat = to_deg(Math.asin(surfacecart.z / r))
    clon = to_deg(Math.atan2(surfacecart.y, surfacecart.x))

    point_point_dist(lat, lon, clat, clon)
  end

  def update_attributes
    super(update_attributes)
    for stop in stops.all
      stop.calculate_preceding(self)
    end
  end

  def to_deg(num)
    num * 180 / Math::PI
  end

  def to_rad(num)
    num * Math::PI / 180
  end

end
