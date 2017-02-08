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
  has_and_belongs_to_many :zonings, autosave: true, after_add: :update_zonings_track, after_remove: :update_zonings_track
  has_many :routes, -> { includes(:stops).order('CASE WHEN vehicle_usage_id IS NULL THEN 0 ELSE routes.id END') }, inverse_of: :planning, autosave: true, dependent: :delete_all
  has_and_belongs_to_many :tags, -> { order('label') }, autosave: true, after_add: :update_tags_track, after_remove: :update_tags_track
  belongs_to :order_array
  belongs_to :vehicle_usage_set, inverse_of: :plannings, validate: true

  nilify_blanks
  auto_strip_attributes :name

  validates :customer, presence: true
  validates :name, presence: true
  validates :vehicle_usage_set, presence: true

  include Consistency
  validate_consistency :vehicle_usage_set, :order_array, :zonings, :tags

  before_create :default_routes, :update_zonings
  before_save :update_zonings
  before_save :update_vehicle_usage_set

  include RefSanitizer

  amoeba do
    enable

    customize(lambda { |_original, copy|
      def copy.update_zonings; end

      def copy.update_vehicle_usage_set; end

      def copy.default_routes; end

      def copy.update_zonings; end

      copy.routes.each{ |route|
        route.planning = copy
      }
    })
  end

  def duplicate
    copy = self.amoeba_dup
    copy.name += " (#{I18n.l(Time.zone.now, format: :long)})"
    copy
  end

  def set_routes(routes_visits, recompute = true, ignore_errors = false)
    default_empty_routes(ignore_errors)
    routes_visits = routes_visits.select{ |ref, _d| ref } # Remove out_of_route
    if routes_visits.size <= routes.size - 1
      visits = routes_visits.values.flat_map{ |s| s[:visits] }.collect{ |visit_active| visit_active[0] }
      routes.find{ |r| !r.vehicle_usage }.set_visits((customer.visits - visits).select{ |visit|
        ((visit.tags | visit.destination.tags) & tags).size == tags.size
      })

      index_routes = (1..routes.size).to_a
      routes_visits.each{ |_ref, r|
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
    route = routes.find{ |route| route.vehicle_usage == vehicle_usage}
    route.stops.select{ |stop| stop.is_a?(StopVisit) }.collect{ |stop|
      routes.find{ |r| !r.vehicle_usage }.stops.build(type: StopVisit.name, visit: stop.visit)
    }
    routes.destroy(route)
  end

  def visit_add(visit)
    routes.find{ |r| !r.vehicle_usage }.add(visit)
  end

  def visit_remove(visit)
    routes.each{ |route|
      route.remove_visit(visit)
    }
  end

  def default_empty_routes(ignore_errors = false)
    routes.clear
    routes.build
    vehicle_usage_set.vehicle_usages.select(&:active).each { |vehicle_usage|
      vehicle_usage_add(vehicle_usage, ignore_errors)
    }
  end

  def default_routes
    if routes.length != vehicle_usage_set.vehicle_usages.select(&:active).length + 1
      default_empty_routes
      routes.find{ |r| !r.vehicle_usage }.default_stops
    end
  end

  def compute(options = {})
    Planning.transaction do
      split_by_zones if zoning_out_of_date
      routes.each{ |r| r.compute(options) }
    end
  end

  def switch(route, vehicle_usage)
    route_prec = routes.find{ |route| route.vehicle_usage == vehicle_usage }
    if route_prec
      need_fetch_stop_status = route_prec.stops.any?{ |s| s.status }

      vehicle_usage_prec = route.vehicle_usage
      route.vehicle_usage = vehicle_usage
      route_prec.vehicle_usage = vehicle_usage_prec

      # Rest sticky with vehicle_usage
      rests_prec = route_prec.stops.select{ |stop| stop.is_a?(StopRest) }
      rests = route.stops.select{ |stop| stop.is_a?(StopRest) }
      rests_prec.each{ |rest|
        move_stop(route, rest, -1, true)
      }
      rests.each{ |rest|
        move_stop(route_prec, rest, -1, true)
      }

      fetch_stops_status if need_fetch_stop_status

      true
    else
      false
    end
  end

  def move_visit(route, visit, index)
    stop = nil
    routes.find{ |route|
      route.stops.find{ |s|
        if s.is_a?(StopVisit) && s.visit == visit
          stop = s
        end
      }
    }
    if stop
      move_stop(route, stop, index)
    end
  end

  def move_stop(route, stop, index, force = false)
    route, index = prefered_route_and_index([route], stop) if !index
    if stop.route != route
      if stop.is_a?(StopVisit)
        visit, active = stop.visit, stop.active
        stop_id = stop.id
        stop.route.move_stop_out(stop)
        route.add(visit, index || 1, active || stop.route.vehicle_usage.nil?, stop_id)
      elsif force && stop.is_a?(StopRest)
        active = stop.active
        stop_id = stop.id
        stop.route.move_stop_out(stop, force)
        route.add_rest(active, stop_id)
      end
      route.compute
    else
      route.move_stop(stop, index || 1)
    end
  end

  def automatic_insert(stop, out_of_zone = true)
    available_routes = []

    # If already in route, stay in route
    if stop.route.vehicle_usage
      available_routes = [stop.route]
    end

    # If zoning, get appropriate route
    if available_routes.empty? && !zonings.empty?
      zone = Zoning.new(zones: zonings.collect(&:zones).flatten).inside(stop.visit.destination)
      if zone && zone.vehicle
        route = routes.find{ |route|
          route.vehicle_usage && route.vehicle_usage.vehicle == zone.vehicle && !route.locked
        }
        (available_routes = [route]) if route
      end
    end

    # It still no route get all routes
    if available_routes.empty? && out_of_zone
      available_routes = routes.select{ |route|
        route.vehicle_usage && !route.locked
      }
    end

    # So, no target route, nothing to do
    if available_routes.empty?
      return
    end

    # Take the closest routes visit and eval insert
    route, index = prefered_route_and_index(available_routes, stop)

    if route
      stop.active = true
      move_stop(route, stop, index || 1)
      return route
    end
  end

  def out_of_date
    routes.inject(false){ |acc, route|
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

    routes.each{ |route|
      if route.vehicle_usage
        route.stops.each{ |stop|
          stop.active = orders.key?(stop.visit_id) && !orders[stop.visit_id].empty?
        }
        route.optimized_at = route.last_sent_to = route.last_sent_at = nil
      end
      route.out_of_date = true
    }

    self.order_array = order_array
    self.date = order_array.base_date + shift
  end

  def optimize(routes, global, &optimizer)
    routes_with_vehicle = routes.select{ |r| r.vehicle_usage }
    stops_on = (routes.find{ |r| !r.vehicle_usage }.try(:stops) || []) + routes_with_vehicle.flat_map{ |r| r.stops_segregate[true] }.compact
    o = amalgamate_stops_same_position(stops_on, global) { |positions|

      services_and_rests = positions.collect{ |position|
        stop_id, open1, close1, open2, close2, duration, vehicle_id, quantities = position[2..9]
        {stop_id: stop_id, start1: open1, end1: close1, start2: open2, end2: close2, duration: duration, vehicle_id: vehicle_id, quantities: quantities}
      }

      unnil_positions(positions, services_and_rests){ |positions, services, rests|
        positions = positions.collect{ |position| position[0..1] }
        vehicles = routes_with_vehicle.collect{ |r|
          position_start = r.vehicle_usage.default_store_start.try(&:position?) ? [r.vehicle_usage.default_store_start.lat, r.vehicle_usage.default_store_start.lng] : nil
          position_stop = r.vehicle_usage.default_store_stop.try(&:position?) ? [r.vehicle_usage.default_store_stop.lat, r.vehicle_usage.default_store_stop.lng] : nil
          # TODO: simplify positions without duplications (for instance same start and stop stores)
          positions = (positions + [position_start, position_stop]).compact

          vehicle_open = r.vehicle_usage.default_open
          vehicle_open += r.vehicle_usage.default_service_time_start - Time.utc(2000, 1, 1, 0, 0) if r.vehicle_usage.default_service_time_start
          vehicle_close = r.vehicle_usage.default_close
          vehicle_close -= r.vehicle_usage.default_service_time_end - Time.utc(2000, 1, 1, 0, 0) if r.vehicle_usage.default_service_time_end
          {
            id: r.vehicle_usage_id,
            router: r.vehicle_usage.vehicle.default_router,
            router_dimension: r.vehicle_usage.vehicle.default_router_dimension,
            router_options: r.vehicle_usage.vehicle.default_router_options.symbolize_keys.except(:time, :distance, :isochrone, :isodistance, :avoid_zones),
            speed_multiplier: r.vehicle_usage.vehicle.default_speed_multiplicator,
            speed_multiplier_areas: Zoning.speed_multiplicator_areas(zonings),
            open: vehicle_open.to_f,
            close: vehicle_close.to_f,
            stores: [position_start && :start, position_stop && :stop].compact,
            rests: rests.select{ |s| s[:vehicle_id] == r.vehicle_usage_id },
            capacities: r.vehicle_usage.vehicle.default_capacities && r.vehicle_usage.vehicle.default_capacities.each.map{ |k, v|
              {
                deliverable_unit_id: k,
                capacity: v,
                overload_multiplier: customer.deliverable_units.find{ |du| du.id == k }.optimization_overload_multiplier || Mapotempo::Application.config.optimize_overload_multiplier
              }
            }
          }
        }

        # Remove out-of-route if no global optimization
        optimizer.call(positions, services, vehicles)[(routes.find{ |r| !r.vehicle_usage } ? 0 : 1)..-1]
      }
    }
    routes_with_vehicle.each_with_index{ |r, i|
      if o[routes.find{ |r| !r.vehicle_usage } ? i + 1 : i].size > 0
        r.optimized_at = Time.now.utc
        r.last_sent_to = r.last_sent_at = nil
      elsif global
        r.optimized_at = r.last_sent_to = r.last_sent_at = nil
      end
    }
    o
  end

  def set_stops(routes, stop_ids)
    raise 'Invalid routes count' unless routes.size == stop_ids.size
    Route.transaction do
      stops_count = routes.collect{ |r| r.stops.size }.reduce(&:+)
      flat_stop_ids = stop_ids.flatten.compact
      routes.each_with_index{ |route, index|
        stops_ = route.stops_segregate

        # Get ordered stops in current route
        ordered_stops = routes.flat_map{ |r| r.stops.select{ |s| stop_ids[index].include? s.id } }.sort_by{ |s| stop_ids[index].index s.id }

        # 1. Set route and index
        i = 0
        ordered_stops.each{ |stop|
          # Don't change route for rests, but build index
          if stop.is_a?(StopRest) && !route.vehicle_usage
            flat_stop_ids.delete stop.id
          else
            stop.route_id = route.id
            if route.vehicle_usage
              stop.active = true
              stop.out_of_window = false
              stop.index = i += 1
            else
              stop.index = stop.time = stop.distance = stop.trace = stop.drive_time = nil
            end
          end
        }

        # 2. Set index for inactive stops in current route
        if route.vehicle_usage
          ((stops_[true] ? stops_[true].select{ |s| s.route_id == route.id && flat_stop_ids.exclude?(s.id) }.sort_by(&:index) : []) - ordered_stops + (stops_[false] ? stops_[false].sort_by(&:index) : [])).each{ |stop|
            stop.active = false
            stop.index = i += 1
          }
        end
      }

      # Save route to update now stop.route_id
      routes.each{ |route|
        route.out_of_date = true
        (route.no_stop_index_validation = true) && route.save!
        route.reload # Refresh route.stops collection if stops have been moved
      }
      raise 'Invalid stops count' unless routes.collect{ |r| r.stops.size }.reduce(&:+) == stops_count
      self.reload # Refresh route.stops collection if stops have been moved
    end
  end

  def fetch_stops_status
    if customer.enable_stop_status
      stops_map = Hash[routes.select(&:vehicle_usage).collect(&:stops).flatten.collect{ |stop| [(stop.is_a?(StopVisit) ? "v#{stop.visit_id}" : "r#{stop.id}"), stop] }]
      stops_map.each{ |ss| ss[1].assign_attributes status: nil, eta: nil }

      Mapotempo::Application.config.devices.each_pair.collect{ |key, device|
        if device.respond_to?(:fetch_stops) && customer.method(key.to_s + '?').call
          device.fetch_stops(self.customer, device.planning_date(self))
        end
      }.compact.flatten.select{ |s|
        # Remove stores
        s[:order_id].to_i == 0
      }.each{ |s|
        if stops_map.key?(s[:order_id])
          stops_map[s[:order_id]].assign_attributes status: s[:status], eta: s[:eta]
        end
      }
    end
  end

  def to_s
    "#{name}=>" + routes.collect(&:to_s).join(' ')
  end

  private

  # To reduce matrix computation with only one route... remove code?
  def amalgamate_stops_same_position(stops, global)
    tws_or_quantities = stops.find{ |stop|
      stop.is_a?(StopRest) || stop.open1 || stop.close1 || stop.open2 || stop.close2
    }
    units_with_default = stops.flat_map{ |stop| stop.is_a?(StopVisit) && stop.visit.default_quantities.try(:keys) }.compact
    multiples_vehicles_with_capacities = stops.collect{ |s| s.route.vehicle_usage_id }.uniq.size > 1 || (stops.size > 0 && (capacities = stops[0].route.vehicle_usage.try(&:vehicle).try(&:default_capacities)) && capacities.any?{ |k, v| units_with_default.include?(k) && v})

    if tws_or_quantities || multiples_vehicles_with_capacities
      # Can't reduce cause of time windows, quantities or multiple vehicles
      positions_uniq = stops.collect{ |stop|
        [stop.lat, stop.lng, stop.id, stop.open1.try(:to_f), stop.close1.try(:to_f), stop.open2.try(:to_f), stop.close2.try(:to_f), stop.duration, (!global || stop.is_a?(StopRest)) ? stop.route.vehicle_usage_id : nil, stop.is_a?(StopVisit) ? stop.visit.default_quantities : nil]
      }

      yield(positions_uniq)
    else
      # Reduce positions vector size by amalgamate points in same position
      stock = Hash.new { [] }
      i = -1
      stops.each{ |stop|
        stock[[stop.lat, stop.lng]] += [[stop, i += 1]]
      }

      positions_uniq = Hash.new { [] }
      stock.each{ |k, v|
        positions_uniq[v[0][0].id] = k + [v[0][0].id, nil, nil, nil, nil, v.sum{ |vs| vs[0].duration }, !global ? v[0][0].route.vehicle_usage_id : nil, v[0][0].is_a?(StopVisit) ? v[0][0].visit.default_quantities : nil]
      }

      optim_uniq = yield(positions_uniq.collect{ |_k, v| v })

      optim_uniq.collect{ |r|
        r.flat_map{ |s|
          stock[positions_uniq[s][0..1]]
        }.collect{ |pa|
          pa[0].id
        }
      }
    end
  end

  def unnil_positions(positions, tws)
    not_nil_position_index = positions.each_with_index.group_by{ |position, _index| !position[0].nil? && !position[1].nil? }

    if not_nil_position_index.key?(true)
      not_nil_position, not_nil_tws = not_nil_position_index[true].collect{ |position, index| [position, tws[index]] }.transpose
    else
      not_nil_position = not_nil_tws = []
    end
    if not_nil_position_index.key?(false)
      nil_tws = not_nil_position_index[false].collect{ |_position, index| tws[index] }
    else
      nil_tws = []
    end

    yield(not_nil_position, not_nil_tws, nil_tws)
  end

  def prefered_route_and_index(available_routes, stop)
    cache_sum_out_of_window = Hash.new{ |h, k| h[k] = k.sum_out_of_window }

    available_routes.flat_map{ |route|
      route.stops.select(&:position?).map{ |stop| [stop.position, route, stop.index] } +
        [route.stops.select(&:position?).empty? ? [route.vehicle_usage.default_store_start, route, 1] : nil,
        (route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.position?) ? [route.vehicle_usage.default_store_stop, route, route.stops.size + 1] : nil]
    }.compact.sort_by{ |a|
      a[0] && a[0].position? ? a[0].distance(stop.position) : 0
    }[0..9].flat_map{ |visit_route_index|
      [[visit_route_index[1], visit_route_index[2]], [visit_route_index[1], visit_route_index[2] + 1]]
    }.uniq.min_by{ |ri|
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
  end

  def update_zonings_track(_zoning)
    @zoning_ids_changed = true
  end

  def zoning_ids_changed?
    @zoning_ids_changed
  end

  def update_tags_track(_tag)
    @tag_ids_changed = true
  end

  def tag_ids_changed?
    @tag_ids_changed
  end

  def split_by_zones
    self.zoning_out_of_date = false
    if !zonings.empty? && !routes.empty?
      # Make sure there is at least one Zone with Vehicle, else, don't apply Zones
      return unless zonings.any?{ |zoning| zoning.zones.any?{ |zone| !zone.avoid_zone && !zone.vehicle_id.blank? } }

      need_fetch_stop_status = routes.any?{ |r| r.stops.any?{ |s| s.status } }

      vehicles_map = Hash[routes.group_by(&:vehicle_usage).map { |vehicle_usage, routes|
        next if vehicle_usage && !vehicle_usage.active?
        [vehicle_usage && vehicle_usage.vehicle, routes[0]]
      }]

      visits_free = routes.select{ |route|
        !route.locked
      }.collect(&:stops).flatten.select{ |stop| stop.is_a?(StopVisit) }.map(&:visit)

      routes.each{ |route|
        route.locked || route.set_visits([])
      }

      Zoning.new(zones: zonings.collect(&:zones).flatten).apply(visits_free).each{ |zone, visits|
        if zone && zone.vehicle && vehicles_map[zone.vehicle] && !vehicles_map[zone.vehicle].locked
          vehicles_map[zone.vehicle].add_visits(visits.collect{ |d| [d, true] })
        else
          # Add to unplanned route even if the route is locked
          routes.find{ |r| !r.vehicle_usage }.add_visits(visits.collect{ |d| [d, true] })
        end
      }

      fetch_stops_status if need_fetch_stop_status
    end
  end

  def update_zonings
    if @zoning_ids_changed
      self.zoning_out_of_date = true
    end

    if !zonings.empty? && @zoning_ids_changed
      self.zoning_out_of_date = true
      split_by_zones
    end
    true
  end

  def update_vehicle_usage_set
    if vehicle_usage_set_id_changed? && !vehicle_usage_set_id_was.nil? && !id.nil?
      h = Hash[routes.select(&:vehicle_usage).collect{ |route| [route.vehicle_usage.vehicle, route] }]
      vehicle_usage_set.vehicle_usages.each{ |vehicle_usage|
        if h[vehicle_usage.vehicle] && vehicle_usage.active
          h[vehicle_usage.vehicle].vehicle_usage = vehicle_usage
          h[vehicle_usage.vehicle].save!
        elsif vehicle_usage.active
          vehicle_usage_add vehicle_usage
        elsif h[vehicle_usage.vehicle]
          vehicle_usage_remove h[vehicle_usage.vehicle].vehicle_usage
        end
      }
      compute
    end
  end
end
