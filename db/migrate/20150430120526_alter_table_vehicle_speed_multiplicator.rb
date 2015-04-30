class AlterTableVehicleSpeedMultiplicator < ActiveRecord::Migration
  def up
    add_column :customers, :speed_multiplicator, :float
    add_column :vehicles, :speed_multiplicator, :float
  end

  def down
    remove_column :customers, :speed_multiplicator
    remove_column :vehicles, :speed_multiplicator
  end
end
