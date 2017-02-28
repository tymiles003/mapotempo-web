class AddRouterOptionsToVehicles < ActiveRecord::Migration
  def change
    add_column :vehicles, :router_options, :hstore, default: {}, null: false
  end
end
