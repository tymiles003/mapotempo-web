class AlterVehicleTomtom < ActiveRecord::Migration
  def change
    add_column :vehicles, :tomtom_id, :string
    add_column :customers, :tomtom_account, :string
    add_column :customers, :tomtom_user, :string
    add_column :customers, :tomtom_password, :string
  end
end
