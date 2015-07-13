class AlterVehicleReference < ActiveRecord::Migration
  def up
    add_column :vehicles, :ref, :string
  end

  def donw
    remove_column :vehicles, :ref
  end
end
