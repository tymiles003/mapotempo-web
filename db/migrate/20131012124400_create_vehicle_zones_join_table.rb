class CreateVehicleZonesJoinTable < ActiveRecord::Migration
  def change
    create_table :vehicles_zones, id: false do |t|
      t.integer :vehicle_id
      t.integer :zone_id
    end
  end
end
