class AddPrecedingCoords < ActiveRecord::Migration
  def self.up
    create_table :preceding_coords do |t|
      t.references :stop
      t.references :route
      t.references :coord
    end
  end

  def self.down
    drop_table :preceding_coords
  end
end