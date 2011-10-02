class Numeric
  # Convert degrees to radians
  def toRad
    self * Math::PI / 180
  end
  
  # Convert radians to degrees
  def toDeg
    self * 180 / Math::PI
  end
end

class Point3D
  attr_accessor :x, :y, :z

  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end

  def to_s
    "(" + @x.to_s + ", " + @y.to_s + ", " + @z.to_s + ")"
  end

  # Subtract another point from this one
  # Returns a new point
  def subtract(point)
    Point3D.new(@x - point.x, @y - point.y, @z - point.z)
  end

  # Add another point to this one
  # Returns a new point
  def add(point)
    Point3D.new(@x + point.x, @y + point.y, @z + point.z)
  end

  # Divide this point by a number
  # Returns a new point
  def divide(num)
    Point3D.new(@x / num, @y / num, @z / num)
  end

  # Multiply this point by a number
  # Returns a new point
  def multiply(num)
    Point3D.new(@x * num, @y * num, @z * num)
  end

  # Calculate the cross product with another point
  # Returns a new point
  def crossProduct(point)
    Point3D.new(
	    @y * point.z - @z * point.y,
		@z * point.x - @x * point.z,
		@x * point.y - @y * point.x)
  end
  
  # Calculate the distance to another point
  def distanceTo(point)
    Math::sqrt((point.x - @x) ** 2 + (point.y - @y) ** 2 + (point.z  - @z) ** 2)
  end
  
  # Get the magnitude of a vector from (0, 0, 0) to this point
  def magnitude()
    Math::sqrt(@x ** 2 + @y ** 2 + @z ** 2)
  end
  
  # Move a point a given distance in the direction of this point
  # Returns a new point
  def moveTowards(point, distance)
    directionVector = point.subtract(self);
	directionVector = directionVector.divide(directionVector.magnitude)
	directionVector.multiply(distance).add(self)
  end
end


class Coordinate
  attr_accessor :latitude, :longitude
  
  def initialize(latitude, longitude)
    @latitude = latitude
	@longitude = longitude
  end
  
  def to_s
    "(" + @latitude.to_s + ", " + @longitude.to_s + ")"
  end
  
  # Calculate the distance to another coordinate
  def distanceTo(coordinate)
    earthRadius = 3956 #miles
	dlong = (coordinate.longitude - @longitude).toRad
	dlat = (coordinate.latitude - @latitude).toRad
	lat1 = @latitude.toRad
	lat2 = coordinate.latitude.toRad
	
	a = Math.sin(dlat / 2) ** 2 + Math::sin(dlong / 2) ** 2 * Math::cos(lat1) * Math::cos(lat2);
	b = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1 - a))
	earthRadius * b;
  end
  
  # Calculate the bearing to another coordinate
  def bearingTowards(coordinate)
    dlong = @latitude - coordinate.latitude
	y = Math::sin(dlong) * Math.cos(coordinate.latitude)
	x = Math::cos(@latitude) * Math::sin(coordinate.latitude) -
	    Math::sin(@latitude) * Math::cos(cooridnate.latitude) * Math::cos(dlong)
	Math::atan2(x, y)
  end
  
  # Calculate the closest coordinate from this coordinate on
  # a line formed by two endpoint coordinates
  # Returns a new coordinate
  def closestPoint(endpoint1, endpoint2)
    r = 3956 #miles
	
	# Convert to cartesian space assuming the earth is a sphere
	ep1cart = Point3D.new(
	    r * Math::cos(endpoint1.latitude.toRad) * Math::cos(endpoint1.longitude.toRad),
		r * Math::cos(endpoint1.latitude.toRad) * Math::sin(endpoint1.longitude.toRad),
		r * Math::sin(endpoint1.latitude.toRad))
	ep2cart = Point3D.new(
	    r * Math::cos(endpoint2.latitude.toRad) * Math::cos(endpoint2.longitude.toRad),
		r * Math::cos(endpoint2.latitude.toRad) * Math::sin(endpoint2.longitude.toRad),
		r * Math::sin(endpoint2.latitude.toRad))
	ptcart = Point3D.new(
	    r * Math::cos(@latitude.toRad) * Math::cos(@longitude.toRad),
		r * Math::cos(@latitude.toRad) * Math::sin(@longitude.toRad),
		r * Math::sin(@latitude.toRad))
	origin = Point3D.new(0, 0, 0)
	
	# Use the 3D point line distance formula to get the distance from the point to the line
	d = ptcart.subtract(ep1cart).crossProduct(ptcart.subtract(ep2cart)).magnitude / ep2cart.subtract(ep1cart).magnitude
	
	# Use trig to find how far away from endpoint1 the "snapped point" is
	hypotenuse = ptcart.distanceTo(ep1cart)
	theta = Math::asin(d / hypotenuse)
	adjacent = d / Math::tan(theta)
	
	# Slide a point down from endpoint1 to endpoint2 to get the location
	# of the snapped point
	closestcart = ep1cart.moveTowards(ep2cart, adjacent)
	
	# The snapped point will end up under the surface of the earth, so we
	# need to slide a point from the center of the earth out towards the surface
	surfacecart = origin.moveTowards(closestcart, r)
	
	# Convert back to lat/lon
	Coordinate.new(Math::asin(surfacecart.z / r).toDeg, Math::atan2(surfacecart.y, surfacecart.y).toDeg)
  end
end