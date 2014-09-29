# Copyright © Mapotempo, 2013-2014
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
class Planning < ActiveRecord::Base
  belongs_to :customer
  belongs_to :zoning
  has_many :routes, -> { order('CASE WHEN vehicle_id IS NULL THEN 0 ELSE id END')}, inverse_of: :planning, :autosave => true, :dependent => :destroy
  has_and_belongs_to_many :tags, -> { order('label')}, :autosave => true

  nilify_blanks
  validates :customer, presence: true
  validates :name, presence: true

  before_create :update_zoning
  before_update :update_zoning

  amoeba do
    enable

    customize(lambda { |original, copy|
      copy.routes.each{ |route|
        route.planning = copy
      }

      def copy.update_zoning
        # No make zoning on duplication
      end
    })

    append :name => Time.now.strftime(" %Y-%m-%d %H:%M")
  end

  def set_destinations(destination_actives, recompute = true)
    default_empty_routes
    if destination_actives.size <= routes.size-1
      destinations = destination_actives.flatten(1).collect{ |destination_active| destination_active[0] }
      routes[0].set_destinations((customer.destinations - destinations).select{ |destination|
        (destination.tags & tags).size == tags.size
      })
      0.upto(destination_actives.size-1).each{ |i|
        routes[i+1].set_destinations(destination_actives[i], recompute)
      }
    else
      raise I18n.t('errors.planning.import_too_routes')
   end
  end

  def vehicle_add(vehicle)
    route = routes.build(vehicle: vehicle, out_of_date:false)
  end

  def vehicle_remove(vehicle)
    route = routes.find{ |route| route.vehicle == vehicle }
    route.stops.collect{ |stop|
      routes[0].stops.build(destination: stop.destination)
      routes[0].out_of_date = true
    }
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
    routes.clear
    r = routes.build
    customer.vehicles.each { |vehicle|
      vehicle_add(vehicle)
    }
  end

  def default_routes
    default_empty_routes
    routes[0].default_stops
  end

  def compute
    if zoning_out_of_date
      split_by_zones
    end
    routes.select{ |route| route.vehicle }.each(&:compute)
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

  def automatic_insert(stop)
    # If zoning, get appropriate route
    available_routes = nil
    if zoning
      zone = zoning.inside(stop.destination)
      if zone && zone.vehicle
        route = routes.find{ |route|
          route.vehicle == zone.vehicle
        }
        (available_routes = [route]) if route
      end
    end

    # It still no route get all routes
    if !available_routes
      available_routes = routes.select{ |route|
          route.vehicle
      }
    end

    cache_sum_out_of_window = Hash.new{ |h,k| h[k] = k.sum_out_of_window }

    # Take the closest routes destination and eval insert
    route, index = available_routes.collect{ |route|
      route.stops.map{ |stop| [stop.destination, route, stop.index] } +
        [[route.vehicle.store_start, route, 0], [route.vehicle.store_stop, route, route.size-1]]
    }.flatten(1).sort{ |a,b|
      a[0].distance(stop.destination) <=> b[0].distance(stop.destination)
    }[0..9].collect{ |destination_route_index|
        [[destination_route_index[1], destination_route_index[2]], [destination_route_index[1], destination_route_index[2]+1]]
    }.flatten(1).uniq.min_by{ |ri|
      ri[0].class.amoeba do
        clone :stops # No need to duplicate stop juste for compute evaluation
        nullify :planning_id
      end

      r = ri[0].amoeba_dup
      r.add(stop.destination, ri[1], true)
      r.compute

      # Difference of total time + difference of sum of out_of_window time
      ((r.end - r.start) - (ri[0].end && ri[0].start ? ri[0].end - ri[0].start : 0)) +
        (r.sum_out_of_window - cache_sum_out_of_window[ri[0]])
    } || [routes[1], 2]

    route.add(stop.destination, index || 2, true)
    route.compute
    stop.destroy
  end

  def out_of_date
    zoning_out_of_date || routes.inject(false){ |acc, route|
      acc or route.out_of_date
    }
  end

  def destinations_compatibles
    customer.destinations.select{ |c|
      tags.to_a & c.tags.to_a == tags.to_a
    }
  end

  def destinations
    routes.collect{ |route|
      route.stops.collect(&:destination)
    }.flatten
  end

  private
    def split_by_zones
      if zoning && !routes.empty?
        vehicles_map = Hash[routes.group_by(&:vehicle).map { |vehicle, routes| [vehicle, routes[0]]}]
        z = {}
        unaffected = []
        destinations_free = routes.select{ |route|
          !route.locked
        }.collect(&:stops).flatten.map(&:destination)

        routes.each{ |route|
          route.locked || route.set_destinations([])
        }
        zoning.apply(destinations_free).each{ |zone, destinations|
          if zone && zone.vehicle && !vehicles_map[zone.vehicle].locked
            vehicles_map[zone.vehicle].set_destinations(destinations.collect{ |d| [d,true]})
          else
            # Add to unplanned route even if the route is locked
            routes[0].add_destinations(destinations.collect{ |d| [d,true]})
          end
        }
      end
      self.zoning_out_of_date = false
    end

    def update_zoning
      if zoning && zoning_id_changed?
        split_by_zones
      end
      true
    end
end
