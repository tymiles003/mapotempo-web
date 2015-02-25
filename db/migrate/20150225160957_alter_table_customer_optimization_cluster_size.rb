class AlterTableCustomerOptimizationClusterSize < ActiveRecord::Migration
  def up
    add_column :customers, :optimization_cluster_size, :integer
  end

  def donw
    remove_column :customers, :optimization_cluster_size
  end
end
