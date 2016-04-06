class AddCustomersAlyacomApiKey < ActiveRecord::Migration
  def change
    add_column :customers, :alyacom_api_key, :string
  end
end
