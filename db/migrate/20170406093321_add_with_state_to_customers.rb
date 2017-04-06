class AddWithStateToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :with_state, :boolean, default: false
  end
end
