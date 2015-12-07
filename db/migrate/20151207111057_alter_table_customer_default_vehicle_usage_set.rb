class AlterTableCustomerDefaultVehicleUsageSet < ActiveRecord::Migration
  def change
    change_column :customers, :enable_multi_vehicle_usage_sets, :boolean, default: false
  end
end
