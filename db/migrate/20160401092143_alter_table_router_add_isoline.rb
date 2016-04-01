class AlterTableRouterAddIsoline < ActiveRecord::Migration
  def change
    add_column :routers, :isochrone, :boolean, null: false, default: false
    add_column :routers, :isodistance, :boolean, null: false, default: false
  end
end
