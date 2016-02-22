class UpdateCustomerAddOrangeFleet < ActiveRecord::Migration
  def change
    add_column :vehicles, :orange_id, :string
    add_column :customers, :enable_orange, :boolean
    add_column :customers, :orange_user, :string
    add_column :customers, :orange_password, :string
  end
end
