class AlterTableCustomerOptimizationTime < ActiveRecord::Migration
  def up
    add_column :customers, :optimization_time, :integer
  end

  def down
    remove_column :customers, :optimization_time
  end
end
