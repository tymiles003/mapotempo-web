class AlterCustomerJobStoreGeocoding < ActiveRecord::Migration
  def up
    remove_index :customers, column: :job_geocoding_id
    rename_column :customers, :job_geocoding_id, :job_destination_geocoding_id
    add_index :customers, :job_destination_geocoding_id, :name => 'index_customers_on_job_destination_geocoding_id'
    add_column :customers, :job_store_geocoding_id, :integer
    add_index :customers, :job_store_geocoding_id, :name => 'index_customers_on_job_store_geocoding_id'
  end

  def down
    remove_index :customers, column: :job_destination_geocoding_id
    rename_column :customers, :job_destination_geocoding_id, :job_geocoding_id
    add_index :customers, :job_geocoding_id, :name => 'index_customers_on_job_geocoding_id'
    remove_column :customers, :job_store_geocoding_id
  end
end
