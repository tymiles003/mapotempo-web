class CreateTableStores < ActiveRecord::Migration
  def up
    create_table :stores do |t|
      t.string :name
      t.string :street
      t.string :postalcode
      t.string :city
      t.float :lat, null: false
      t.float :lng, null: false
      t.time :open
      t.time :close
      t.references :customer, null: false, foreign_key: { deferrable: true }

      t.timestamps
    end

    add_column :vehicles, :store_start_id, :integer, foreign_key: { references: :stores, deferrable: true }
    add_column :vehicles, :store_stop_id, :integer, foreign_key: { references: :stores, deferrable: true }

    add_column :routes, :stop_trace, :text
    add_column :routes, :stop_out_of_drive_time, :boolean
    add_column :routes, :stop_distance, :float

    create_table :stores_vehicules, id: false do |t|
      t.integer :store_id, index: true, null: false
      t.integer :vehicle_id, index: true, null: false
    end

    Route.all.each{ |route|
      route.stop_trace = route.stops[-1].trace
      route.stop_out_of_drive_time = route.stops[-1].out_of_drive_time
      route.stop_distance = route.stops[-1].distance
    }

    Customer.all.each{ |customer|
      store = Destination.find(customer.store_id)
      new_store = customer.stores.build(store.attributes.slice('name', 'street', 'postalcode', 'city', 'lat', 'lng', 'open', 'close'))
      store.destroy
      customer.vehicles.each{ |vehicle|
        vehicle.store_start = new_store
        vehicle.store_stop = new_store
        vehicle.save!
      }
    }

    Stop.all.each{ |stop|
      if stop.index
        stop.index -= 1
        stop.save!
      end
    }

    Destination.all.select{ |d| not d.customer }.each(&:destroy)

    change_column :destinations, :customer_id, :integer, null: false, foreign_key: { deferrable: true }

    change_column :vehicles, :store_start_id, :integer, null: false, foreign_key: { references: :stores, deferrable: true }
    change_column :vehicles, :store_stop_id, :integer, null: false, foreign_key: { references: :stores, deferrable: true }

    remove_column :customers, :store_id
  end
end
