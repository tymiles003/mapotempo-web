class AlterTableCustomerOptimizationSoftUpperBound < ActiveRecord::Migration
  def up
    add_column :customers, :optimization_soft_upper_bound, :integer
  end

  def down
    remove_column :customers, :optimization_soft_upper_bound
  end
end
