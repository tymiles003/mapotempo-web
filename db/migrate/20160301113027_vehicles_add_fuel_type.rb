class VehiclesAddFuelType < ActiveRecord::Migration
  def change
    add_column :vehicles, :fuel_type, :string
  end
end
