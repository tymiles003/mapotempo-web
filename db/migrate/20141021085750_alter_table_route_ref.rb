class AlterTableRouteRef < ActiveRecord::Migration
  def up
    add_column :routes, :ref, :string
  end

  def down
    remove_column :routes, :ref
  end
end
