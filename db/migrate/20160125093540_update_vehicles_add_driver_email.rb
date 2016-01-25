class UpdateVehiclesAddDriverEmail < ActiveRecord::Migration
  def change
    add_column :vehicles, :contact_email, :string
  end
end
