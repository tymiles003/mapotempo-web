class AddPartBoolToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :enable_global_optimization, :boolean, default: false, null: false
  end
end
