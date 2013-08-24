class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :store, :class_name => "Destination", :autosave => true, :dependent => :destroy
  belongs_to :layer
  belongs_to :job_geocoding, :class_name => "Delayed::Backend::ActiveRecord::Job"
  belongs_to :job_optimizer, :class_name => "Delayed::Backend::ActiveRecord::Job"
  has_many :vehicles, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :destinations, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :plannings, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :tags, -> { order('label')}, :autosave => true, :dependent => :destroy

  after_initialize :assign_defaults, if: 'new_record?'
  before_update :update_out_of_date, :update_max_vehicles

  private
    def assign_defaults
      self.max_vehicles = 0
      self.layer_id = 1
      self.store = Destination.create(name:"Store", city:"Bordeaux", lat:44.83423, lng:-0.60068)
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
            vehicle = Vehicle.new(name: "Vehcile #{vehicles.size+1}")
            vehicle.user = self
            vehicles << vehicle
            plannings.each{ |planning|
              planning.vehicle_add(vehicle)
            }
          }
        elsif vehicles.size > max_vehicles
          # Delete
          (vehicles.size - max_vehicles).times{ |i|
            vehicle = vehicles.pop
            plannings.each{ |planning|
              planning.vehcile_remove(vehicle)
            }
            vehicle.destroy
          }
        end
      end
    end
end
