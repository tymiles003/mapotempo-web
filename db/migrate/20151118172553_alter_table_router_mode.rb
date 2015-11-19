class AlterTableRouterMode < ActiveRecord::Migration
  def up
    change_column :routers, :mode, :string, null: false
  end

  def down
    change_column :routers, :mode, :string
  end
end
