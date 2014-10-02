class AlterTableCustomerPrintHeader < ActiveRecord::Migration
  def up
    add_column :customers, :print_header, :text
  end

  def down
    remove_column :customers, :print_header
  end
end
