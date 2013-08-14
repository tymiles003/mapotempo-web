class Planning < ActiveRecord::Base
  belongs_to :user
  has_many :routes, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_and_belongs_to_many :tags, -> { order('label')}

#  validates :user, presence: true
#  validates :name, presence: true

  def set_destinations(destinations)
    default_empty_route
    routes[0].set_destinations([])
    if destinations.size <= routes.size-1
      0.upto(destinations.size-1).each{ |i|
        routes[i+1].set_destinations(destinations[i].collect{ |d| [d, true] })
      }
    else
      # FIXME erreur, pas assez de véhicules
   end
  end

  def vehicle_add(vehicle)
    route = Route.create(planning: self, vehicle: vehicle, out_of_date:true)
    route.default_store
    routes << route
  end

  def vehicle_remove(vehicle)
    route = routes.find{ |route| route.vehicle == vehicle }
    routes[0].stops += route.stops.select{ |stop| stop.destination != user.store }.collect{ |stop| Stop.new(destination: stop.destination, route: route[0]) }
    routes[0].out_of_date = true
    route.destroy
  end

  def destination_add(destination)
    routes[0].add(destination)
  end

  def destination_remove(destination)
    routes.each{ |route|
      route.remove(destination)
    }
  end

  def default_empty_routes
    routes << Route.create(planning: self)
    user.vehicles.each { |vehicle|
      vehicle_add(vehicle)
    }
  end

  def default_routes
    default_empty_routes
    routes[1].default_stops
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
