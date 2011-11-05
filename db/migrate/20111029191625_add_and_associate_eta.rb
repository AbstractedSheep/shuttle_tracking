class AddAndAssociateEta < ActiveRecord::Migration
  def self.up
    create_table :etas do |t|
      t.datetime :timestamp
      t.references :stop
      t.references :vehicle
    end
  end

  def self.down
    drop_table :etas
  end
end
