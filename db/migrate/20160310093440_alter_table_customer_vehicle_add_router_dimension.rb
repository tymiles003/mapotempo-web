class AlterTableCustomerVehicleAddRouterDimension < ActiveRecord::Migration
  def up
    add_column :customers, :router_dimension, :integer, null: false, default: 'time'
    add_column :vehicles, :router_dimension, :integer
  end

  def down
    remove_column :customers, :router_dimension
    remove_column :vehicles, :router_dimension
  end
end
