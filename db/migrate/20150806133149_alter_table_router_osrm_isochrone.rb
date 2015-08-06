class AlterTableRouterOsrmIsochrone < ActiveRecord::Migration
  def up
    add_column :routers, :url_isochrone, :string
  end

  def down
    remove_column :routers, :url_isochrone
  end
end
