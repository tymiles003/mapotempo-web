class UpdateCustomersAddUrl < ActiveRecord::Migration
  def change
    add_column :customers, :external_callback_url, :string
    add_column :customers, :external_callback_name, :string
    add_column :customers, :enable_external_callback, :boolean, null: false, default: false
  end
end
