class AlterTableZoneStoreRevert < ActiveRecord::Migration
  def up
    remove_column :zones, :store_id
  end

  def down
    add_column :zones, :store_id, :integer
  end
end
