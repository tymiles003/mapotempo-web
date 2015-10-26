class AlterCustomerAddPrintStopTime < ActiveRecord::Migration
  def up
    add_column :customers, :print_stop_time, :boolean, default: true, null: false
  end

  def down
    remove_column :customers, :print_stop_time
  end
end
