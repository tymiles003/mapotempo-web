class AlterTableRouterAddMode < ActiveRecord::Migration
  def up
    add_column :routers, :mode, :string
  end

  def down
    remove_column :routers, :mode
  end
end
