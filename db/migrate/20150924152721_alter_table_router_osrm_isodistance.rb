class AlterTableRouterOsrmIsodistance < ActiveRecord::Migration
  def up
    add_column :routers, :url_isodistance, :string
  end

  def down
    remove_column :routers, :url_isodistance
  end
end
