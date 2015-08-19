class AlterTableRouteAddColor < ActiveRecord::Migration
  def up
    add_column :routes, :color, :string
  end

  def down
    remove_column :routes, :color
  end
end
