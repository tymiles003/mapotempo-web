class AddForceStartToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :optimization_force_start, :boolean, default: false, null: false
  end
end
