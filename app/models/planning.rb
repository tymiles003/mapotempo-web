# Copyright © Mapotempo, 2013-2016
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
  has_many :routes, -> { includes(:stops).order('CASE WHEN vehicle_usage_id IS NULL THEN 0 ELSE routes.id END') }, inverse_of: :planning, autosave: true, dependent: :delete_all
  has_and_belongs_to_many :tags, -> { order('label') }, autosave: true
  belongs_to :order_array
  belongs_to :vehicle_usage_set, inverse_of: :plannings

  nilify_blanks
  auto_strip_attributes :name, :ref
  validates :customer, presence: true
  validates :name, presence: true
  validates :vehicle_usage_set, presence: true

  before_create :default_routes, :update_zoning
  before_save :update_zoning
  before_save :update_vehicle_usage_set

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

    append name: ' ' + I18n.l(Time.now, format: :long)
  end

  def set_routes(routes_visits, recompute = true, ignore_errors = false)
    default_empty_routes(ignore_errors)
    routes_visits = routes_visits.select{ |ref, _d| ref } # Remove out_of_route
    if routes_visits.size <= routes.size - 1
      visits = routes_visits.values.collect{ |s| s[:visits] }.flatten(1).collect{ |visit_active| visit_active[0] }
      routes[0].set_visits((customer.visits - visits).select{ |visit|
        ((visit.tags | visit.destination.tags) & tags).size == tags.size
      })

      index_routes = (1..routes.size).to_a
      routes_visits.each{ |ref, r|
        index_routes.delete(routes.index{ |rr| rr.vehicle_usage && rr.vehicle_usage.vehicle.ref == r[:ref_vehicle] }) if r[:ref_vehicle]
      }
      routes_visits.each{ |ref, r|
        i = routes.index{ |rr| r[:ref_vehicle] && rr.vehicle_usage && rr.vehicle_usage.vehicle.ref == r[:ref_vehicle] } || index_routes.shift
        routes[i].ref = ref
        routes[i].set_visits(r[:visits].select{ |visit|
          ((visit[0].tags | visit[0].destination.tags) & tags).size == tags.size
        }, recompute, ignore_errors)
      }
    else
      raise I18n.t('errors.planning.import_too_routes')
   end
  end

  def vehicle_usage_add(vehicle_usage, ignore_errors = false)
    route = routes.build(vehicle_usage: vehicle_usage, out_of_date: false)
    vehicle_usage.routes << route if !vehicle_usage.id
    route.init_stops(ignore_errors)
  end

  def vehicle_usage_remove(vehicle_usage)
    route = routes.find{ |route| route.vehicle_usage == vehicle_usage }
    route.stops.select{ |stop| stop.is_a?(StopVisit) }.collect{ |stop|
      routes[0].stops.build(type: StopVisit.name, visit: stop.visit)
      routes[0].out_of_date = true
    }
    routes.destroy(route)
  end

  def visit_add(visit)
    routes[0].add(visit)
  end

  def visit_remove(visit)
    routes.each{ |route|
      route.remove_visit(visit)
    }
  end

  def default_empty_routes(ignore_errors = false)
    routes.clear
    routes.build
    vehicle_usage_set.vehicle_usages.each { |vehicle_usage|
      vehicle_usage_add(vehicle_usage, ignore_errors)
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
    routes.select(&:vehicle_usage).select(&:out_of_date).each(&:compute)
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
      zone = zoning.inside(stop.visit.destination)
      if zone && zone.vehicle
        route = routes.find{ |route|
          route.vehicle_usage && route.vehicle_usage.vehicle == zone.vehicle && !route.locked
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

    # Take the closest routes visit and eval insert
    route, index = available_routes.collect{ |route|
      route.stops.select(&:position?).map{ |stop| [stop.position, route, stop.index] } +
        [(route.vehicle_usage.default_store_start && !route.vehicle_usage.default_store_start.lat.nil? && !route.vehicle_usage.default_store_start.lng.nil?) ? [route.vehicle_usage.default_store_start, route, 1] : nil,
        (route.vehicle_usage.default_store_stop && !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil?) ? [route.vehicle_usage.default_store_stop, route, route.stops.size + 1] : nil]
    }.flatten(1).compact.sort_by{ |a|
      a[0].distance(stop.position)
    }[0..9].collect{ |visit_route_index|
      [[visit_route_index[1], visit_route_index[2]], [visit_route_index[1], visit_route_index[2] + 1]]
    }.flatten(1).uniq.min_by{ |ri|
      ri[0].class.amoeba do
        clone :stops # No need to duplicate stop juste for compute evaluation
        nullify :planning_id
      end

      r = ri[0].amoeba_dup
      if stop.is_a?(StopVisit)
        r.add(stop.visit, ri[1], true)
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

  def visits_compatibles
    customer.visits.select{ |visit|
      tags.to_a & (visit.tags.to_a | visit.destination.tags.to_a) == tags.to_a
    }
  end

  def visits
    routes.collect{ |route|
      route.stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit)
    }.flatten
  end

  def apply_orders(order_array, shift)
    orders = order_array.orders.select{ |order|
      order.shift == shift && !order.products.empty?
    }.collect{ |order|
      [order.visit_id, order.products]
    }
    orders = Hash[orders]

    routes.select(&:vehicle_usage).each{ |route|
      route.stops.each{ |stop|
        stop.active = orders.key?(stop.visit_id) && !orders[stop.visit_id].empty?
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
      vehicles_map = Hash[routes.group_by(&:vehicle_usage).map { |vehicle_usage, routes| [vehicle_usage && vehicle_usage.vehicle, routes[0]] }]
      visits_free = routes.select{ |route|
        !route.locked
      }.collect(&:stops).flatten.select{ |stop| stop.is_a?(StopVisit) }.map(&:visit)

      routes.each{ |route|
        route.locked || route.set_visits([])
      }
      zoning.apply(visits_free).each{ |zone, visits|
        if zone && zone.vehicle && !vehicles_map[zone.vehicle].locked
          vehicles_map[zone.vehicle].set_visits(visits.collect{ |d| [d, true] })
        else
          # Add to unplanned route even if the route is locked
          routes[0].add_visits(visits.collect{ |d| [d, true] })
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

  def update_vehicle_usage_set
    if vehicle_usage_set_id_changed? && !vehicle_usage_set_id_was.nil? && !id.nil?
      h = Hash[routes.select(&:vehicle_usage).collect{ |route| [route.vehicle_usage.vehicle, route] }]
      vehicle_usage_set.vehicle_usages.each{ |vehicle_usage|
        h[vehicle_usage.vehicle].vehicle_usage = vehicle_usage
        h[vehicle_usage.vehicle].save!
      }
      compute
    end
  end
end
