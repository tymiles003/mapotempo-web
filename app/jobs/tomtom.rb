# Copyright © Mapotempo, 2014-2015
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
class Tomtom

  def self.fetch_devices(customer)
    Mapotempo::Application.config.tomtom.showObjectReport(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password)
  end

  def self.clear(route)
    customer = route.planning.customer
    Mapotempo::Application.config.tomtom.clearOrders(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle_usage.vehicle.tomtom_id)
  end

  def self.export_route_as_orders(route)
    date = route.planning.date || Date.today.to_time
    customer = route.planning.customer
    position = route.vehicle_usage.default_store_start
    if position && !position.lat.nil? && !position.lng.nil?
      Mapotempo::Application.config.tomtom.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle_usage.vehicle.tomtom_id, date, position, -1, route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.name || "#{position.lat} #{position.lng}", route.start)
    end
    route.stops.select(&:active).each{ |stop|
      position = stop if stop.position?
      if (position && !position.lat.nil? && !position.lng.nil?) || position.is_a?(StopRest)
        description = [
          '',
          stop.name,
          stop.is_a?(StopVisit) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.visit.quantity && stop.visit.quantity > 1 ? "x#{stop.visit.quantity}" : nil) : nil,
          stop.is_a?(StopVisit) ? (stop.visit.take_over ? '(' + stop.visit.take_over.strftime('%H:%M:%S') + ')' : nil) : route.vehicle_usage.default_rest_duration.strftime('%H:%M:%S'),
          stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
          stop.detail,
          stop.comment,
          stop.phone_number,
        ].compact.join(' ').strip
        Mapotempo::Application.config.tomtom.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle_usage.vehicle.tomtom_id, date, position, stop.id, description, stop.time)
      end
    }
    position = route.vehicle_usage.default_store_stop
    if !position.nil? && !position.lat.nil? && !position.lng.nil?
      Mapotempo::Application.config.tomtom.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle_usage.vehicle.tomtom_id, date, position, -2, route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.name || "#{position.lat} #{position.lng}", route.start)
    end
  end

  def self.export_route_as_waypoints(route)
    date = route.planning.date || Date.today
    customer = route.planning.customer
    position = route.vehicle_usage.default_store_start
    waypoint_start = (route.vehicle_usage.default_store_start && !route.vehicle_usage.default_store_start.lat.nil? && !route.vehicle_usage.default_store_start.lng.nil?) ? [[
        route.vehicle_usage.default_store_start.lat,
        route.vehicle_usage.default_store_start.lng,
        '',
        route.vehicle_usage.default_store_start.name
      ]] : []
    waypoint_stop = (route.vehicle_usage.default_store_stop && !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil?) ? [[
        route.vehicle_usage.default_store_stop.lat,
        route.vehicle_usage.default_store_stop.lng,
        '',
        route.vehicle_usage.default_store_stop.name
      ]] : []
    waypoints = route.stops.select(&:active).collect{ |stop|
        position = stop if stop.position?
        if position.nil? || position.lat.nil? || position.lng.nil?
          next
        end
        [
          position.lat,
          position.lng,
          '',
          stop.is_a?(StopVisit) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.visit.quantity && stop.visit.quantity > 1 ? "x#{stop.visit.quantity}" : nil) : nil,
          stop.name,
          stop.comment,
          stop.phone_number
        ]
    }
    waypoints = (waypoint_start + waypoints.compact + waypoint_stop).map{ |l|
        description = l[2..-1].compact.join(' ').strip
        {lat: l[0], lng: l[1], description: description}
    }
    position = route.vehicle_usage.default_store_stop if route.vehicle_usage.default_store_stop && !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil?
    description = route.ref || (waypoints[-1] && waypoints[-1][:description]) || "#{waypoints[-1][:lat]} #{waypoints[-1][:lng]}"
    Mapotempo::Application.config.tomtom.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle_usage.vehicle.tomtom_id, date, position, route.vehicle_usage.id, description, route.start, waypoints)
  end

  def self.current_position(customer)
    Mapotempo::Application.config.tomtom.showObjectReport(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password)
  end
end
