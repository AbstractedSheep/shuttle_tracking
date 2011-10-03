class Route < ActiveRecord::Base

  # Relations
  has_and_belongs_to_many :stops
  has_many :vehicles
  has_many :coords, :dependent => :destroy
  
  # Validations
  validates :name, :presence => true
  validates :width, :numericality => { :greater_than_or_equal_to => 0 }

  # Scopes, so I don't have to type so much.
  scope :enabled, where(:enabled => true)
  scope :disabled, where(:enabled => false)

  accepts_nested_attributes_for :coords, :allow_destroy => true

  def distanceTo(latitude, longitude)
    shortestDistance = 1000
    endpoint1 = nil

    for endpoint2 in coords
      if endpoint1.nil?
        endpoint1 = coords.last
      end
      
      newDist = ((endpoint2.latitude - endpoint1.latitude)*(endpoint1.longitude - longitude) - (endpoint1.latitude - latitude)*(endpoint2.longitude - endpoint1.longitude)).abs/Math.sqrt((endpoint2.latitude - endpoint1.latitude) ** 2 + (endpoint2.longitude - endpoint1.longitude) ** 2)

      if newDist < shortestDistance
        shortestDistance = newDist
      end

      endpoint1 = endpoint2
    end

    shortestDistance
  end

end
