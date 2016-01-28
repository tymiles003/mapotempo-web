class AlterTableStoreAddIconSize < ActiveRecord::Migration
  def up
    add_column :stores, :icon_size, :string
  end
  def down
    remove_column :stores, :icon_size
  end
end
