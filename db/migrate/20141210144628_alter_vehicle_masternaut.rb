class AlterVehicleMasternaut < ActiveRecord::Migration
  def up
    add_column :vehicles, :masternaut_ref, :string
    add_column :customers, :masternaut_account, :string
    add_column :customers, :masternaut_user, :string
    add_column :customers, :masternaut_password, :string
  end

  def down
    remove_column :vehicles, :masternaut_ref
    remove_column :customers, :masternaut_account
    remove_column :customers, :masternaut_user
    remove_column :customers, :masternaut_password
  end
end
