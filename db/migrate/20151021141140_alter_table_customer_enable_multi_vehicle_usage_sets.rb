class AlterTableCustomerEnableMultiVehicleUsageSets < ActiveRecord::Migration
  def up
    add_column :customers, :enable_multi_vehicle_usage_sets, :boolean, default: true, null: false
  end

  def down
    remove_column :customers, :enable_multi_vehicle_usage_sets
  end
end
