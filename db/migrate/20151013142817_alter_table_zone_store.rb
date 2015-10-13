class AlterTableZoneStore < ActiveRecord::Migration
  def up
    add_column :zones, :store_id, :integer
  end

  def down
    remove_column :zones, :store_id
  end
end
