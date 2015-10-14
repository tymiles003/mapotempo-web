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
  has_many :routes, -> { includes(:stops).order('vehicle_usage_id ASC NULLS FIRST')}, inverse_of: :planning, autosave: true, dependent: :delete_all
  has_and_belongs_to_many :tags, -> { order('label')}, autosave: true
  belongs_to :order_array
  belongs_to :vehicle_usage_set, inverse_of: :plannings

  nilify_blanks
  auto_strip_attributes :name, :ref
  validates :customer, presence: true
  validates :name, presence: true
  validates :vehicle_usage_set, presence: true

  before_create :default_routes
  before_save :update_zoning

  amoeba do
    enable

    customize(lambda { |_original, copy|
      copy.routes.each{ |route|
        route.planning = copy
      }

      def copy.update_zoning
        # No make zoning on duplication
      end
    })

    append name: Time.now.strftime(' %Y-%m-%d %H:%M')
  end

  def set_destinations(destination_actives, recompute = true)
    default_empty_routes
    destination_actives = destination_actives.select{ |ref, _d| ref }
    if destination_actives.size <= routes.size - 1
      destinations = destination_actives.values.flatten(1).collect{ |destination_active| destination_active[0] }
      routes[0].set_destinations((customer.destinations - destinations).select{ |destination|
        (destination.tags & tags).size == tags.size
      })
      i = 0
      destination_actives.each{ |ref, destinations|
        routes[i += 1].ref = ref
        routes[i].set_destinations(destinations.select{ |destination|
          (destination[0].tags & tags).size == tags.size
        }, recompute)
      }
    else
      raise I18n.t('errors.planning.import_too_routes')
   end
  end

  def vehicle_usage_add(vehicle_usage)
    route = routes.build(vehicle_usage: vehicle_usage, out_of_date: false)
    route.init_stops
  end

  def vehicle_usage_remove(vehicle_usage)
    route = routes.find{ |route| route.vehicle_usage == vehicle_usage }
    route.stops.select{ |stop| stop.is_a?(StopDestination) }.collect{ |stop|
      routes[0].stops.build(type: StopDestination.name, destination: stop.destination)
      routes[0].out_of_date = true
    }
    routes.destroy(route)
  end

  def destination_add(destination)
    routes[0].add(destination)
  end

  def destination_remove(destination)
    routes.each{ |route|
      route.remove_destination(destination)
    }
  end

  def default_empty_routes
    routes.clear
    routes.build
    vehicle_usage_set.vehicle_usages.each { |vehicle_usage|
      vehicle_usage_add(vehicle_usage)
    }
  end

  def default_routes
    if routes.length != vehicle_usage_set.vehicle_usages.length + 1
      default_empty_routes
      routes[0].default_stops
    end
  end

  def compute
    if zoning_out_of_date
      split_by_zones
    end
    routes.select(&:vehicle_usage).each(&:compute)
  end

  def switch(route, vehicle_usage)
    route_prec = routes.find{ |route| route.vehicle_usage == vehicle_usage }
    if route_prec
      vehicle_usage_prec = route.vehicle_usage
      route.vehicle_usage = vehicle_usage
      route_prec.vehicle_usage = vehicle_usage_prec

      # Rest sticky with vehicle_usage
      stops_prec = route_prec.stops.select{ |stop| stop.is_a?(StopRest) }
      stops = route.stops.select{ |stop| stop.is_a?(StopRest) }
      stops_prec.each{ |stop|
        route.move_stop(stop, -1, true)
      }
      stops.each{ |stop|
        route_prec.move_stop(stop, -1, true)
      }
    else
      false
    end
  end

  def automatic_insert(stop)
    available_routes = []

    # If already in route, stay in route
    if stop.route.vehicle_usage
      available_routes = [stop.route]
    end

    # If zoning, get appropriate route
    if available_routes.empty? && zoning
      zone = zoning.inside(stop.destination)
      if zone && zone.vehicle_usage
        route = routes.find{ |route|
          route.vehicle_usage.vehicle == zone.vehicle && !route.locked
        }
        (available_routes = [route]) if route
      end
    end

    # It still no route get all routes
    if available_routes.empty?
      available_routes = routes.select{ |route|
        route.vehicle_usage && !route.locked
      }
    end

    # So, no target route, nothing to do
    if available_routes.empty?
      return
    end

    cache_sum_out_of_window = Hash.new{ |h, k| h[k] = k.sum_out_of_window }

    # Take the closest routes destination and eval insert
    route, index = available_routes.collect{ |route|
      route.stops.select(&:position?).map{ |stop| [stop.position, route, stop.index] } +
        [(route.vehicle_usage.default_store_start && !route.vehicle_usage.default_store_start.lat.nil? && !route.vehicle_usage.default_store_start.lng.nil?) ? [route.vehicle_usage.default_store_start, route, 1] : nil,
        (route.vehicle_usage.default_store_stop && !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil?) ? [route.vehicle_usage.default_store_stop, route, route.stops.size + 1] : nil]
    }.flatten(1).compact.sort{ |a, b|
      a[0].distance(stop.position) <=> b[0].distance(stop.position)
    }[0..9].collect{ |destination_route_index|
      [[destination_route_index[1], destination_route_index[2]], [destination_route_index[1], destination_route_index[2] + 1]]
    }.flatten(1).uniq.min_by{ |ri|
      ri[0].class.amoeba do
        clone :stops # No need to duplicate stop juste for compute evaluation
        nullify :planning_id
      end

      r = ri[0].amoeba_dup
      if stop.is_a?(StopDestination)
        r.add(stop.destination, ri[1], true)
      else
        r.add_rest(ri[1], true)
      end
      r.compute

      # Difference of total time + difference of sum of out_of_window time
      ((r.end - r.start) - (ri[0].end && ri[0].start ? ri[0].end - ri[0].start : 0)) +
        (r.sum_out_of_window - cache_sum_out_of_window[ri[0]])
    }

    if route
      stop.active = true
      route.move_stop(stop, index || 1)
    end
  end

  def out_of_date
    zoning_out_of_date || routes.inject(false){ |acc, route|
      acc || route.out_of_date
    }
  end

  def destinations_compatibles
    customer.destinations.select{ |c|
      tags.to_a & c.tags.to_a == tags.to_a
    }
  end

  def destinations
    routes.collect{ |route|
      route.stops.select{ |stop| stop.is_a?(StopDestination) }.collect(&:destination)
    }.flatten
  end

  def apply_orders(order_array, shift)
    orders = order_array.orders.select{ |order|
      order.shift == shift && !order.products.empty?
    }.collect{ |order|
      [order.destination_id, order.products]
    }
    orders = Hash[orders]

    routes.select(&:vehicle_usage).each{ |route|
      route.stops.each{ |stop|
        stop.active = orders.key?(stop.destination_id) && !orders[stop.destination_id].empty?
      }
      route.out_of_date = true
    }

    self.order_array = order_array
    self.date = order_array.base_date + shift
  end

  def to_s
    "#{name}=>" + routes.collect(&:to_s).join(' ')
  end

  private

  def split_by_zones
    if zoning && !routes.empty?
      vehicles_map = Hash[routes.group_by(&:vehicle_usage).map { |vehicle_usage, routes| [vehicle_usage && vehicle_usage.vehicle, routes[0]]}]
      destinations_free = routes.select{ |route|
        !route.locked
      }.collect(&:stops).flatten.select{ |stop| stop.is_a?(StopDestination) }.map(&:destination)

      routes.each{ |route|
        route.locked || route.set_destinations([])
      }
      zoning.apply(destinations_free).each{ |zone, destinations|
        if zone && zone.vehicle && !vehicles_map[zone.vehicle].locked
          vehicles_map[zone.vehicle].set_destinations(destinations.collect{ |d| [d, true]})
        else
          # Add to unplanned route even if the route is locked
          routes[0].add_destinations(destinations.collect{ |d| [d, true]})
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
