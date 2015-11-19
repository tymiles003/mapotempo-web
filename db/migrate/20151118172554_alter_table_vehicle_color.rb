class AlterTableVehicleColor < ActiveRecord::Migration
  def up
    change_column :vehicles, :color, :string, null: false
  end

  def down
    change_column :vehicles, :color, :string
  end
end
