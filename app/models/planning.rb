class Planning < ActiveRecord::Base
  belongs_to :user
  has_many :routes, :autosave => true, :dependent => :destroy
  has_and_belongs_to_many :tags

#  validates :user, presence: true
#  validates :name, presence: true

  def set_destinations(destinations)
    default_empty_routes
    routes[0].set_destinations([])
    if destinations.size <= routes.size-1
      0.upto(destinations.size-1).each{ |i|
        routes[i+1].set_destinations(destinations[i].collect{ |d| [d, true] })
      }
    else
      # FIXME erreur, pas assez de véhicules
    end
  end

  def default_empty_routes
    routes << Route.create(planning: self)
    user.vehicles.each { |v|
      routes << Route.create(planning: self, vehicle: v)
    }
  end

  def default_routes
    default_empty_routes
    routes[0].default_stops
    routes[1..-1].each { |route|
      route.default_store
    }
  end

  def compute
    routes.each(&:compute)
  end

  def switch(route, vehicle)
    route_prec = routes.find{ |route| route.vehicle == vehicle }
    if route_prec
      vehicle_prec = route.vehicle
      route.vehicle = vehicle
      route_prec.vehicle = vehicle_prec
    else
      false
    end
  end
end
