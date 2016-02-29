class AlterTableZoneAddName < ActiveRecord::Migration
  def up
    add_column :zones, :name, :string
  end
  def down
    remove_column :zones, :name
  end
end
