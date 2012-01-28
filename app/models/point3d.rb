class Point3D
  attr_accessor :x, :y, :z

  def cross_product(point)
    result = Point3D.new()
    result.x = self.x * point.z - self.z * point.y
    result.y = self.z * point.x - self.x * point.z
    result.z = self.x * point.y - self.y * point.x
    result
  end

  def magnitude
    Math.sqrt(self.x**2 + self.y**2 + self.z**2)
  end

  def move_towards(point, distance)
    direction_vector = point.minus(self)
    direction_vector = direction_vector.divide(direction_vector.magnitude)
    direction_vector.times(distance).plus(self)
  end

  def minus(point)
    result = Point3D.new
    result.x = self.x - point.x
    result.y = self.y - point.y
    result.z = self.z - point.z
  end

  def plus(point)
    result = Point3D.new
    result.x = self.x + point.x
    result.y = self.y + point.y
    result.z = self.z + point.z
  end

  def times(number)
    result = Point3D.new
    result.x = self.x * number
    result.y = self.y * number
    result.z = self.z * number
  end

  def divide(number)
    result = Point3D.new
    result.x = self.x / number
    result.y = self.y / number
    result.z = self.z / number
  end

  def distance_to(point)
    Math.sqrt((point.x - self.x) ** 2 + (point.y - self.y) ** 2 + (point.z - self.z) ** 2)
  end
end