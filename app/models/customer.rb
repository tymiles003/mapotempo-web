class Customer < ActiveRecord::Base
  belongs_to :store, :class_name => "Destination", :autosave => true, :dependent => :destroy
  belongs_to :job_geocoding, :class_name => "Delayed::Backend::ActiveRecord::Job"
  belongs_to :job_matrix, :class_name => "Delayed::Backend::ActiveRecord::Job"
  belongs_to :job_optimizer, :class_name => "Delayed::Backend::ActiveRecord::Job"
  has_many :vehicles, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :destinations, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :plannings, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :tags, -> { order('label')}, :autosave => true, :dependent => :destroy
  has_many :users
  has_many :zonings

  validates :name, presence: true
  validates :destinations, length: { maximum: 1000, message: :over_max_limit }

  after_initialize :assign_defaults, if: 'new_record?'
  before_create :update_max_vehicles
  before_update :update_out_of_date, :update_max_vehicles

  def destination_add(destination)
    self.destinations << destination
    self.plannings.each { |planning|
      if planning.tags & destination.tags == planning.tags
        planning.destination_add(destination)
      end
    }
  end

  private
    def assign_defaults
      self.store = Destination.create(
        name: I18n.t('destinations.default_store_name'),
        city: I18n.t('destinations.default_store_city'),
        lat: Float(I18n.t('destinations.default_store_lat')),
        lng: Float(I18n.t('destinations.default_store_lng'))
      )
    end

    def update_out_of_date
      if take_over_changed?
        Route.transaction do
          plannings.each{ |planning|
            planning.routes.each{ |route|
              route.out_of_date = true
            }
          }
        end
      end
    end

    def update_max_vehicles
      if max_vehicles_changed?
        if vehicles.size < max_vehicles
          # Add new
          (max_vehicles - vehicles.size).times{ |i|
            vehicle = Vehicle.new(name: I18n.t('vehicles.default_name', n:vehicles.size+1))
            vehicle.customer = self
            vehicles << vehicle
            plannings.each{ |planning|
              planning.vehicle_add(vehicle)
            }
          }
        elsif vehicles.size > max_vehicles
          # Delete
          (vehicles.size - max_vehicles).times{ |i|
            vehicle = vehicles[vehicles.size-i-1]
            plannings.each{ |planning|
              planning.vehicle_remove(vehicle)
            }
            vehicle.destroy
          }
        end
      end
    end
end
