class AlterTableCustomerTest < ActiveRecord::Migration
  def up
    add_column :customers, :test, :boolean, :default => false, :null => false
  end

  def donw
    remove_column :customers, :test
  end
end
