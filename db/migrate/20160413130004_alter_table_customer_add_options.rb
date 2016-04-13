class AlterTableCustomerAddOptions < ActiveRecord::Migration
  def change
    add_column :customers, :advanced_options, :text
  end
end
