class AlterCustomerSoftUpperBounds < ActiveRecord::Migration
  def up
    change_column :customers, :optimization_stop_soft_upper_bound, :float
    change_column :customers, :optimization_vehicle_soft_upper_bound, :float
  end
  def down
    change_column :customers, :optimization_stop_soft_upper_bound, :integer
    change_column :customers, :optimization_vehicle_soft_upper_bound, :integer
  end
end
