class AlterTableVehicleUsageSetStoreNull < ActiveRecord::Migration
  def up
    change_column :vehicle_usage_sets, :store_start_id, :integer, null: true
    change_column :vehicle_usage_sets, :store_stop_id, :integer, null: true
  end

  def down
    change_column :vehicle_usage_sets, :store_start_id, :integer, null: false
    change_column :vehicle_usage_sets, :store_stop_id, :integer, null: false
  end
end
