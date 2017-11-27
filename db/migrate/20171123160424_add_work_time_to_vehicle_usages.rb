class AddWorkTimeToVehicleUsages < ActiveRecord::Migration
  def change
    add_column :vehicle_usages, :work_time, :integer
  end
end
