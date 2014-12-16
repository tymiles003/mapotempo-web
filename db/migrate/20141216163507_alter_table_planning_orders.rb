class AlterTablePlanningOrders < ActiveRecord::Migration
  def up
    add_column :plannings, :order_array_id, :integer, foreign_key: { deferrable: true }
    add_column :plannings, :order_array_shift, :integer
  end

  def down
    remove_column :plannings, :order_array_id
    remove_column :plannings, :order_array_shift
  end
end
