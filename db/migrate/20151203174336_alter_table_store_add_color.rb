class AlterTableStoreAddColor < ActiveRecord::Migration
  def up
    add_column :stores, :color, :string
  end
  def down
    remove_column :stores, :color
  end
end
