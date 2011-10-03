class AssociateVehiclesAndRoutes < ActiveRecord::Migration
  def self.up
    change_table :vehicles do |t|
      t.references :route
    end
  end

  def self.down
    remove_column :vehicles, :route_id
  end
end
