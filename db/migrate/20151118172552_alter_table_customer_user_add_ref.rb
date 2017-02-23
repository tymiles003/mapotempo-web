class AlterTableCustomerUserAddRef < ActiveRecord::Migration
  def up
    add_column :customers, :ref, :string
    add_column :users, :ref, :string
  end

  def down
    remove_column :users, :ref
    remove_column :customers, :ref
  end
end
