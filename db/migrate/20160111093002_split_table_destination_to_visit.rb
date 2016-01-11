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
    add_foreign_key :stops, :visits
    add_index :stops, :visit_id

    add_column :orders, :visit_id, :integer
    add_foreign_key :orders, :visits
    add_index :orders, :visit_id

    # Split Destination data
    Destination.all.each{ |destination|
      visit = destination.visits.create!(quantity: destination.quantity, open: destination.open, close: destination.close, ref: destination.ref, take_over: destination.take_over, tags: destination.tags)
      destination.stop_destinations.each{ |stop|
        stop.visit_id = visit.id
        stop.save!
      }
      destination.orders.each{ |order|
        order.visit_id = visit.id
        order.save!
      }
      destination.save!
    }

    change_column :orders, :visit_id, :integer, null: false

    remove_column :stops, :destination_id
    remove_column :orders, :destination_id

    StopDestination.update_all(type: StopVisit.name)

    # Remove moved field from Destination
    remove_column :destinations, :quantity, :float
    remove_column :destinations, :open, :time
    remove_column :destinations, :close, :time
    remove_column :destinations, :ref, :string
    remove_column :destinations, :take_over, :time

    drop_table :destinations_tags
  end

  def down
    fake_missing_props

    Customer.parent.const_set('StopDestination', Class.new(StopVisit))

    # Back field on Destination
    add_column :destinations, :quantity, :float
    add_column :destinations, :open, :time
    add_column :destinations, :close, :time
    add_column :destinations, :ref, :string
    add_column :destinations, :take_over, :time

    create_table :destinations_tags, id: false, force: :cascade do |t|
      t.integer :destination_id, null: false
      t.integer :tag_id, null: false
    end

    add_index :destinations_tags, :destination_id
    add_foreign_key :destinations_tags, :destinations
    add_index :destinations_tags, :tag_id
    add_foreign_key :destinations_tags, :tags

    # Link Stop and Order to Destination
    add_column :stops, :destination_id, :integer
    add_foreign_key :stops, :destinations
    add_index :stops, :destination_id

    add_column :orders, :destination_id, :integer
    add_foreign_key :orders, :destinations
    add_index :orders, :destination_id

    # Move Visit into Destination
    Visit.all.each{ |visit|
      visit.destination.update(quantity: visit.quantity, open: visit.open, close: visit.close, ref: visit.ref, tags: visit.tags)
      visit.stop_destinations.each{ |stop|
        stop.destination_id = visit.destination.id
        stop.save!
      }
      visit.orders.each{ |order|
        order.destination_id = visit.destination.id
        order.save!
      }
    }

    change_column :orders, :destination_id, :integer, null: false

    remove_column :stops, :visit_id
    remove_column :orders, :visit_id

    StopVisit.update_all(type: StopDestination.name)

    # Remove Visit table
    drop_table :tags_visits
    drop_table :visits
  end

  private

  def fake_missing_props
    # Reest removed prop for migration purpose
    Destination.class_eval do
      has_many :stop_destinations, inverse_of: :destination, dependent: :delete_all
      has_many :orders, inverse_of: :destination, dependent: :delete_all
      has_many :visits, inverse_of: :destination, dependent: :destroy
      has_and_belongs_to_many :tags

      skip_callback :save, :before, :update_tags
      skip_callback :save, :before, :create_orders
    end

    Visit.class_eval do
      belongs_to :destination
      has_many :stop_destinations, inverse_of: :destination, dependent: :delete_all
      has_many :orders, inverse_of: :destination, dependent: :delete_all
      has_and_belongs_to_many :tags

      skip_callback :save, :before, :update_tags
      skip_callback :save, :before, :create_orders
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
