class VehicleUsageAddEnabled < ActiveRecord::Migration
  def change
    add_column :vehicle_usages, :active, :boolean, default: true
  end
end
