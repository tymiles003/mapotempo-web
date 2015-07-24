class AlterTableDestinationLatlng < ActiveRecord::Migration
  def up
    change_column :stores, :lat, :float, null: true
    change_column :stores, :lng, :float, null: true
  end
  def down
    change_column :stores, :lat, :float, null: false
    change_column :stores, :lng, :float, null: false
  end
end
