class AlterTableStoreAddIcon < ActiveRecord::Migration
  def up
    add_column :stores, :icon, :string
  end
  def down
    remove_column :stores, :icon
  end
end
