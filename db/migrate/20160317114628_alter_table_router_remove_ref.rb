class AlterTableRouterRemoveRef < ActiveRecord::Migration
  def change
    remove_columns :routers, :ref
  end
end
