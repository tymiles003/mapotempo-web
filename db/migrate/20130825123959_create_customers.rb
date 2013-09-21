class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.date :end_subscription
      t.integer :max_vehicles
      t.integer :take_over
      t.references :store, index: true
      t.references :job_geocoding, index: true
      t.references :job_matrix, index: true
      t.references :job_optimizer, index: true

      t.timestamps
    end
  end
end
