class CreateVehicleUsage < ActiveRecord::Migration
  def up
    fake_missing_props

    create_table :vehicle_usage_sets do |t|
      t.integer :customer_id, null: false
      t.string :name, null: false
      t.time :open, null: false
      t.time :close, null: false
      t.integer :store_start_id, null: false
      t.integer :store_stop_id, null: false
      t.integer :store_rest_id
      t.time :rest_start
      t.time :rest_stop
      t.time :rest_duration
    end

    add_index :vehicle_usage_sets, :customer_id
    add_index :vehicle_usage_sets, :store_start_id
    add_index :vehicle_usage_sets, :store_stop_id
    add_index :vehicle_usage_sets, :store_rest_id

    add_foreign_key :vehicle_usage_sets, :customers
    add_foreign_key :vehicle_usage_sets, :stores, column: :store_start_id
    add_foreign_key :vehicle_usage_sets, :stores, column: :store_stop_id
    add_foreign_key :vehicle_usage_sets, :stores, column: :store_rest_id

    create_table :vehicle_usages do |t|
      t.integer :vehicle_usage_set_id, null: false
      t.integer :vehicle_id, null: false
      t.time :open
      t.time :close
      t.integer :store_start_id
      t.integer :store_stop_id
      t.integer :store_rest_id
      t.time :rest_start
      t.time :rest_stop
      t.time :rest_duration
    end

    add_index :vehicle_usages, :vehicle_usage_set_id
    add_index :vehicle_usages, :vehicle_id
    add_index :vehicle_usages, :store_start_id
    add_index :vehicle_usages, :store_stop_id
    add_index :vehicle_usages, :store_rest_id

    add_foreign_key :vehicle_usages, :vehicle_usage_sets
    add_foreign_key :vehicle_usages, :vehicles
    add_foreign_key :vehicle_usages, :stores, column: :store_start_id
    add_foreign_key :vehicle_usages, :stores, column: :store_stop_id
    add_foreign_key :vehicle_usages, :stores, column: :store_rest_id

    # Move vehicle props values to vehicle_usage

    stats = Hash.new{ |h, k| h[k] = Hash.new(0) }
    Customer.all.each{ |customer|
      vehicle_usage_set = customer.vehicle_usage_sets.build(name: 'Default')
      vehicle_usage_set.vehicle_usages = customer.vehicles.collect{ |vehicle|
        stats[:open][vehicle.open] += 1
        stats[:close][vehicle.close] += 1
        stats[:store_start][vehicle.store_start] += 1
        stats[:store_stop][vehicle.store_stop] += 1
        stats[:store_rest][vehicle.store_rest] += 1
        stats[:rest_start][vehicle.rest_start] += 1
        stats[:rest_stop][vehicle.rest_stop] += 1
        stats[:rest_duration][vehicle.rest_duration] += 1

        vehicle_usage_set.vehicle_usages.build(
          vehicle: vehicle,
          open: vehicle.open,
          close: vehicle.close,
          store_start: vehicle.store_start,
          store_stop: vehicle.store_stop,
          store_rest: vehicle.store_rest,
          rest_start: vehicle.rest_start,
          rest_stop: vehicle.rest_stop,
          rest_duration: vehicle.rest_duration
        )
      }

      # Set most fequent values as default
      vehicle_usage_set.open = stats[:open].max_by(&:last)[0]
      vehicle_usage_set.close = stats[:close].max_by(&:last)[0]
      vehicle_usage_set.store_start = stats[:store_start].max_by(&:last)[0]
      vehicle_usage_set.store_stop = stats[:store_stop].max_by(&:last)[0]
      vehicle_usage_set.store_rest = stats[:store_rest].max_by(&:last)[0]
      vehicle_usage_set.rest_start = stats[:rest_start].max_by(&:last)[0]
      vehicle_usage_set.rest_stop = stats[:rest_stop].max_by(&:last)[0]
      vehicle_usage_set.rest_duration = stats[:rest_duration].max_by(&:last)[0]

      customer.save!
    }

    remove_column :vehicles, :open
    remove_column :vehicles, :close
    remove_column :vehicles, :store_start_id
    remove_column :vehicles, :store_stop_id
    remove_column :vehicles, :store_rest_id
    remove_column :vehicles, :rest_start
    remove_column :vehicles, :rest_stop
    remove_column :vehicles, :rest_duration

    # Set default vehicle_usage_sets to plannings

    add_column :plannings, :vehicle_usage_set_id, :integer
    add_index :plannings, :vehicle_usage_set_id
    add_foreign_key :plannings, :vehicle_usage_sets

    add_column :routes, :vehicle_usage_id, :integer
    add_index :routes, :vehicle_usage_id
    add_foreign_key :routes, :vehicle_usages

    Customer.all.each{ |customer|
      vehicle_usage_set = customer.vehicle_usage_sets.first
      h = Hash[vehicle_usage_set.vehicle_usages.collect{ |vehicle_usage| [vehicle_usage.vehicle, vehicle_usage] }]
      customer.plannings.each{ |planning|
        planning.vehicle_usage_set = vehicle_usage_set

        # Use vehicle_usage in route in place of vehicle
        planning.routes.each{ |route|
          if route.vehicle
            route.vehicle_usage = h[route.vehicle]
          end
        }
      }
      customer.save!
    }

    change_column :plannings, :vehicle_usage_set_id, :integer, null: false

    remove_column :routes, :vehicle_id
  end

  def down
    fake_missing_props

    add_column :routes, :vehicle_id, :integer
    add_foreign_key :routes, :vehicles
    add_index :routes, :vehicle_id

    add_column :vehicles, :open, :time
    add_column :vehicles, :close, :time
    add_column :vehicles, :store_start_id, :integer
    add_index :vehicles, :store_start_id
    add_column :vehicles, :store_stop_id, :integer
    add_index :vehicles, :store_stop_id
    add_column :vehicles, :store_rest_id, :integer
    add_index :vehicles, :store_rest_id
    add_column :vehicles, :rest_start, :time
    add_column :vehicles, :rest_stop, :time
    add_column :vehicles, :rest_duration, :time

    add_foreign_key :vehicles, :stores, column: :store_start_id
    add_foreign_key :vehicles, :stores, column: :store_stop_id
    add_foreign_key :vehicles, :stores, column: :store_rest_id

    Customer.all.each{ |customer|
      customer.plannings.each{ |planning|
        planning.routes.select(&:vehicle).each{ |route|
          route.vehicle = route.vehicle_usage.vehicle
          route.save!
        }
      }

      h = Hash[customer.vehicle_usage_sets[0].vehicle_usages.collect{ |vehicle_usage| [vehicle_usage.vehicle, vehicle_usage] }]
      customer.vehicles.each{ |vehicle|
        vehicle_usage = h[vehicle]
        vehicle_usage_set = vehicle_usage.vehicle_usage_set
        vehicle.open = vehicle_usage.open || vehicle_usage_set.open
        vehicle.close = vehicle_usage.close || vehicle_usage_set.close
        vehicle.store_start = vehicle_usage.store_start || vehicle_usage_set.store_start
        vehicle.store_stop = vehicle_usage.store_stop || vehicle_usage_set.store_stop
        vehicle.store_rest = vehicle_usage.store_rest || vehicle_usage_set.store_rest
        vehicle.rest_start = vehicle_usage.rest_start || vehicle_usage_set.rest_start
        vehicle.rest_stop = vehicle_usage.rest_stop || vehicle_usage_set.rest_stop
        vehicle.rest_duration = vehicle_usage.rest_duration || vehicle_usage_set.rest_duration
        vehicle.save!
      }
    }

    change_column :vehicles, :open, :time, null: false
    change_column :vehicles, :close, :time, null: false
    change_column :vehicles, :store_start_id, :integer, null: false
    change_column :vehicles, :store_stop_id, :integer, null: false

    remove_column :plannings, :vehicle_usage_set_id

    remove_column :routes, :vehicle_usage_id

    drop_table :vehicle_usages
    drop_table :vehicle_usage_sets
  end

  def fake_missing_props
    # Reest removed prop for migration purpose
    Vehicle.class_eval do
      belongs_to :store_start, class_name: 'Store', inverse_of: :vehicle_starts
      belongs_to :store_stop, class_name: 'Store', inverse_of: :vehicle_stops
      belongs_to :store_rest, class_name: 'Store', inverse_of: :vehicle_rests
      has_many :routes, inverse_of: :vehicle, dependent: :delete_all, autosave: true
    end

    Store.class_eval do
      has_many :vehicle_starts, class_name: 'Vehicle', inverse_of: :store_start, foreign_key: 'store_start_id'
      has_many :vehicle_stops, class_name: 'Vehicle', inverse_of: :store_stop, foreign_key: 'store_stop_id'
      has_many :vehicle_rests, class_name: 'Vehicle', inverse_of: :store_rest, foreign_key: 'store_rest_id', dependent: :nullify
    end

    Route.class_eval do
      belongs_to :vehicle
    end
  end
end
