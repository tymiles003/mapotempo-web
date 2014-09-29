class DropTableVehiclesZones < ActiveRecord::Migration
  def change
    add_column :zones, :vehicle_id, :integer, foreign_key: { deferrable: true }

    execute "UPDATE zones SET vehicle_id = (SELECT vehicle_id FROM vehicles_zones WHERE vehicles_zones.zone_id = zones.id ORDER BY vehicle_id LIMIT 1)"

    drop_table :vehicles_zones
  end
end
