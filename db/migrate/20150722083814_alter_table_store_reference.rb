class AlterTableStoreReference < ActiveRecord::Migration
  def up
    add_column :stores, :ref, :string
  end

  def donw
    remove_column :stores, :ref
  end
end
