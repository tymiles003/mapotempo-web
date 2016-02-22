class UpdateCustomerAddTeksat < ActiveRecord::Migration
  def change
    add_column :customers, :enable_teksat, :boolean
    add_column :customers, :teksat_customer_id, :integer
    add_column :customers, :teksat_username, :string
    add_column :customers, :teksat_password, :string
    add_column :customers, :teksat_url, :string
  end
end
