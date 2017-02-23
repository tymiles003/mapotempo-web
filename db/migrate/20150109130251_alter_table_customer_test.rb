class AlterTableCustomerTest < ActiveRecord::Migration
  def up
    add_column :customers, :test, :boolean, :default => false, :null => false
  end

  def down
    remove_column :customers, :test
  end
end
