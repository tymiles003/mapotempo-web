class UpdateVehicleAddTeksatId < ActiveRecord::Migration
  def change
    add_column :vehicles, :teksat_id, :string
  end
end
