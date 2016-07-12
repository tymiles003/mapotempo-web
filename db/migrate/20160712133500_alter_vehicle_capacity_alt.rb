class AlterVehicleCapacityAlt < ActiveRecord::Migration
  def change
    rename_column :vehicles, :capacity, :capacity1_1
    rename_column :vehicles, :capacity_unit, :capacity1_1_unit
    add_column :vehicles, :capacity1_2, :integer
    add_column :vehicles, :capacity1_2_unit, :string
    rename_column :visits, :quantity, :quantity1_1
    add_column :visits, :quantity1_2, :float
  end
end
