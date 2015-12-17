class AddCapacityUnitToVehicle < ActiveRecord::Migration
  def up
    add_column :vehicles, :capacity_unit, :string
  end

  def down
    remove_column :vehicles, :capacity_unit
  end
end
