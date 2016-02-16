class AlterTableVehicleUsageAddCreatedAt < ActiveRecord::Migration
  def up
    add_column :vehicle_usage_sets, :created_at, :datetime
    add_column :vehicle_usage_sets, :updated_at, :datetime

    add_column :vehicle_usages, :created_at, :datetime
    add_column :vehicle_usages, :updated_at, :datetime
  end

  def down
    remove_column :vehicle_usage_sets, :created_at
    remove_column :vehicle_usage_sets, :updated_at

    remove_column :vehicle_usages, :created_at
    remove_column :vehicle_usages, :updated_at
  end
end
