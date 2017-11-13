class AlterCustomerAddPlanningsLimitation < ActiveRecord::Migration
  def change
    add_column :customers, :plannings_limitation, :integer
    add_column :customers, :zonings_limitation, :integer
    add_column :customers, :destinations_limitation, :integer
    add_column :customers, :vehicle_usage_sets_limitation, :integer
  end
end
