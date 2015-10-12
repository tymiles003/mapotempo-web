class AlterTableRouterUrlDistance < ActiveRecord::Migration
  def up
    add_column :routers, :url_distance, :string
    rename_column :routers, :url, :url_time
  end

  def down
    remove_column :routers, :url_distance
    rename_column :routers, :url_time, :url
  end
end
