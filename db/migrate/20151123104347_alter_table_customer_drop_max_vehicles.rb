class AlterTableCustomerDropMaxVehicles < ActiveRecord::Migration
  def up
    remove_column :customers, :max_vehicles
  end

  def donw
    add_column :customers, :max_vehicles, :integer, null: false
  end
end
