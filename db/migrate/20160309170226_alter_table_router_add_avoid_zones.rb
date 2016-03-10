class AlterTableRouterAddAvoidZones < ActiveRecord::Migration
  def up
    add_column :routers, :avoid_zones, :boolean, default: false, null: false
    add_column :zones, :speed_multiplicator, :float, default: 1, null: false
    change_column :customers, :speed_multiplicator, :float, default: 1, null: false
  end
  def down
    remove_column :routers, :avoid_zones
    remove_column :zones, :speed_multiplicator
  end
end
