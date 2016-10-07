class AlterCustomerVehicleSoftUpperBound < ActiveRecord::Migration
  def change
    rename_column :customers, :optimization_soft_upper_bound, :optimization_stop_soft_upper_bound
    add_column :customers, :optimization_vehicle_soft_upper_bound, :integer
  end
end
