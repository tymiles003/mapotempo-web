class UpdateVehicleUsagesAddDurationBeforeAfter < ActiveRecord::Migration
  def change
    add_column :vehicle_usage_sets, :service_time_start, :time
    add_column :vehicle_usage_sets, :service_time_end, :time
    add_column :vehicle_usages, :service_time_start, :time
    add_column :vehicle_usages, :service_time_end, :time
  end
end
