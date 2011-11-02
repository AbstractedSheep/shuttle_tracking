class PrecedingCoord < ActiveRecord::Base
  belongs_to :stop
  belongs_to :route
  belongs_to :coord
end