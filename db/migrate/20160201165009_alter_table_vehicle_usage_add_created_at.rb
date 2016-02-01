class AlterTableVehicleUsageAddCreatedAt < ActiveRecord::Migration
  def up
    add_column :vehicle_usage_sets, :created_at, :datetime
    add_column :vehicle_usage_sets, :updated_at, :datetime

    add_column :vehicle_usages, :created_at, :datetime
    add_column :vehicle_usages, :updated_at, :datetime

    now = DateTime.now

    VehicleUsageSet.all.each{ |vus|
      vus.created_at = vus.updated_at = now
      vus.save!
    }

    VehicleUsage.all.each{ |vu|
      vu.created_at = vu.updated_at = now
      vu.save!
    }
  end

  def down
    remove_column :vehicle_usage_sets, :created_at
    remove_column :vehicle_usage_sets, :updated_at

    remove_column :vehicle_usages, :created_at
    remove_column :vehicle_usages, :updated_at
  end
end
