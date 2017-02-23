class AlterTableStoreReference < ActiveRecord::Migration
  def up
    add_column :stores, :ref, :string
  end

  def down
    remove_column :stores, :ref
  end
end
