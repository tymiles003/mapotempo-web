class SplitTableDestinationToVisit < ActiveRecord::Migration
  def up
    fake_missing_props

    Customer.parent.const_set('StopDestination', Class.new(StopVisit))

    # Create Visits
    create_table :visits do |t|
      t.float :quantity
      t.time :open
      t.time :close
      t.string :ref
      t.time :take_over
      t.references :destination

      t.timestamps
    end

    add_foreign_key :visits, :destinations, on_delete: :cascade
    add_index :visits, :destination_id

    create_table :tags_visits, id: false, force: :cascade do |t|
      t.integer :visit_id, null: false
      t.integer :tag_id, null: false
    end

    add_foreign_key :tags_visits, :visits, on_delete: :cascade
    add_index :tags_visits, :visit_id
    add_foreign_key :tags_visits, :tags, on_delete: :cascade
    add_index :tags_visits, :tag_id

    # Link Stop and Order to Visit
    add_column :stops, :visit_id, :integer
    add_foreign_key :stops, :visits, on_delete: :cascade
    add_index :stops, :visit_id

    add_column :orders, :visit_id, :integer
    add_foreign_key :orders, :visits, on_delete: :cascade
    add_index :orders, :visit_id

    # Remove rest with 0 duration
    Customer.find_each{ |customer|
      customer.vehicle_usage_sets.each{ |vehicle_usage_set|
        if vehicle_usage_set.rest_duration == Time.new(2000, 1, 1, 0, 0, 0, '+00:00')
          vehicle_usage_set.rest_duration = nil
          vehicle_usage_set.rest_start = nil
          vehicle_usage_set.rest_stop = nil
          vehicle_usage_set.save!
        end
        vehicle_usage_set.vehicle_usages.each{ |vehicle_usage|
          if vehicle_usage.rest_duration == Time.new(2000, 1, 1, 0, 0, 0, '+00:00')
            vehicle_usage.rest_duration = nil
            vehicle_usage.rest_start = nil if vehicle_usage.default_rest_duration.nil?
            vehicle_usage.rest_stop = nil if vehicle_usage.default_rest_duration.nil?
            vehicle_usage.save!
          end
        }
      }
      customer.save!
    }

    # Split Destination data
    total = Destination.count
    count = 0
    Rails::logger.info "#{total} destinations"
    puts "#{total} destinations"
    Customer.find_each{ |customer|
      customer.destinations.each{ |destination|
        if (count += 1) % 100 == 0
          Rails::logger.info "#{count} / #{total}"
          puts "#{count} / #{total}"
        end
        visit = destination.visits.create!(quantity: destination.quantity, open: destination.open, close: destination.close, take_over: destination.take_over)
        vid = visit.id
        destination.stop_destinations.all.each{ |stop|
          stop.visit_id = vid
          stop.save!
        }
        destination.orders.all.each{ |order|
          order.visit_id = vid
          order.save!
        }
      }
    }
    change_column :orders, :visit_id, :integer, null: false

    remove_column :stops, :destination_id
    remove_column :orders, :destination_id

    StopDestination.update_all(type: StopVisit.name)

    raise '# visits and # destinations are different' if Visit.count != total
    raise 'At least one destination without visit' if Destination.includes(:visits).select{ |d| d.visits.size == 0 }.size != 0
    stops = Stop.where(type: 'StopVisit', visit_id: nil)
    raise ('At least one stop without visit: ' + stops.inspect) if stops.size != 0

    # Remove moved field from Destination
    remove_column :destinations, :quantity, :float
    remove_column :destinations, :open, :time
    remove_column :destinations, :close, :time
    remove_column :destinations, :take_over, :time
  end

  def down
    fake_missing_props

    Customer.parent.const_set('StopDestination', Class.new(StopVisit))

    # Back field on Destination
    add_column :destinations, :quantity, :float
    add_column :destinations, :open, :time
    add_column :destinations, :close, :time
    add_column :destinations, :take_over, :time

    # Link Stop and Order to Destination
    add_column :stops, :destination_id, :integer
    add_foreign_key :stops, :destinations, on_delete: :cascade
    add_index :stops, :destination_id

    add_column :orders, :destination_id, :integer
    add_foreign_key :orders, :destinations, on_delete: :cascade
    add_index :orders, :destination_id

    # Move Visit into Destination
    total = Destination.count
    count = 0
    Rails::logger.info "#{total} destinations"
    puts "#{total} destinations"
    empty_visit = Visit.new
    Customer.find_each{ |customer|
      customer.destinations.each{ |destination|
        if (count += 1) % 100 == 0
          Rails::logger.info "#{count} / #{total}"
          puts "#{count} / #{total}"
        end
        visit = destination.visits.first || empty_visit
        destination.update(quantity: visit.quantity, open: visit.open, close: visit.close, ref: visit.ref, tags: visit.tags)
        visit.stop_visits.each{ |stop|
          stop.destination_id = destination.id
          stop.save!
        }
        destination.visits.each_with_index{ |visit, i|
          visit.orders.each{ |order|
            if i == 0
              order.destination_id = destination.id
              order.save!
            else
              order.destroy!
            end
          }
        }

        if destination.visits.size > 1
          (destination.visits.to_a - [visit]).each{ |visit|
            visit.stop_visits.each{ |stop|
              stop.route.out_of_date = true
              stop.route.save!
            }
          }
        end

        destination.save!
      }
      customer.save!
    }

    change_column :orders, :destination_id, :integer, null: false

    remove_column :stops, :visit_id
    remove_column :orders, :visit_id

    StopVisit.update_all(type: StopDestination.name)

    # Remove Visit table
    drop_table :tags_visits
    drop_table :visits

    stops = Stop.where(type: 'StopDestination', destination_id: nil)
    raise ('Remaining some StopDestination without destination_id: ' + stops.inspect) if stops.size > 0
    
  end

  private

  def fake_missing_props
    # Reest removed prop for migration purpose
    Destination.class_eval do
      has_many :stop_destinations, inverse_of: :destination, dependent: :delete_all
      has_many :orders, inverse_of: :destination, dependent: :delete_all
      has_many :visits, inverse_of: :destination, dependent: :destroy
      has_and_belongs_to_many :tags

      skip_callback :update, :before, :update_tags
      skip_callback :update, :before, :create_orders
    end

    Visit.class_eval do
      belongs_to :destination
      has_many :stop_destinations, inverse_of: :destination, dependent: :delete_all
      has_many :orders, inverse_of: :destination, dependent: :delete_all
      has_and_belongs_to_many :tags

      skip_callback :update, :before, :update_tags
      skip_callback :update, :before, :create_orders
    end

    Stop.class_eval do
      belongs_to :destination
      belongs_to :visit
    end

    Order.class_eval do
      belongs_to :destination
      belongs_to :visit
    end
  end
end
