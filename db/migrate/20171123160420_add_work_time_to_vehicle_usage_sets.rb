class AddWorkTimeToVehicleUsageSets < ActiveRecord::Migration
  def change
    add_column :vehicle_usage_sets, :work_time, :integer
  end
end
