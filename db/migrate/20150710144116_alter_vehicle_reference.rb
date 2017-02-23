class AlterVehicleReference < ActiveRecord::Migration
  def up
    add_column :vehicles, :ref, :string
  end

  def down
    remove_column :vehicles, :ref
  end
end
