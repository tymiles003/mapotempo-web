class AlterTableCustomerAddPrintMap < ActiveRecord::Migration
  def change
    add_column :customers, :print_map, :boolean, null: false, default: false
  end
end
