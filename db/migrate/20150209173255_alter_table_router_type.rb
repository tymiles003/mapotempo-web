class AlterTableRouterType < ActiveRecord::Migration
  def up
    change_column :routers, :url, :string, null: true
    add_column :routers, :type, :string, default: 'RouterOsrm', null: false

    RouterHere.create!(name: "Here")
  end

  def down
    change_column :routers, :url, :string, null: false
    remove_column :routers, :type
  end
end
