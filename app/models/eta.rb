class Eta < ActiveRecord::Base
  set_table_name "etas"

  belongs_to :stop
  belongs_to :vehicle
  validates :timestamp, :presence => true
end