class Shuttle < ActiveRecord::Base
  has_many :positions
  
  def current_position
    self.positions.find(:first, :order => 'timestamp DESC')
  end
end
