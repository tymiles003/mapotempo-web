class AddRouterOptionsToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :router_options, :hstore, default: {}, null: false
  end
end
