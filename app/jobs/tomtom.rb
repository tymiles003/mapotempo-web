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
require 'tomtom_webfleet'

class Tomtom

  def self.fetch_device_id(customer)
    TomtomWebfleet.showObjectReport(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password)
  end

  def self.clear(route)
    customer = route.planning.customer
    TomtomWebfleet.clearOrders(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id)
  end

  def self.export_route_as_orders(route)
    date = route.planning.date || Date.today.to_time
    customer = route.planning.customer
    position = route.vehicle.store_start
    if !position.nil? && !position.lat.nil? && !position.lng.nil?
      TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, position, -1, route.vehicle.store_start.name, route.start)
    end
    route.stops.select(&:active).each{ |stop|
      position = stop if stop.position?
      if (!position.nil? && !position.lat.nil? && !position.lng.nil?) || position.is_a?(StopRest)
        description = [
          '',
          stop.name,
          stop.is_a?(StopDestination) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil) : nil,
          stop.is_a?(StopDestination) ? (stop.destination.take_over ? '(' + stop.destination.take_over.strftime('%H:%M:%S') + ')' : nil) : route.vehicle.rest_duration.strftime("%H:%M:%S"),
          stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
          stop.detail,
          stop.comment,
        ].select{ |s| s }.join(' ').strip
        TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, position, stop.id, description, stop.time)
      end
    }
    position = route.vehicle.store_stop
    if !position.nil? && !position.lat.nil? && !position.lng.nil?
      TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, position, -2, route.vehicle.store_stop.name, route.start)
    end
  end

  def self.export_route_as_waypoints(route)
    date = route.planning.date || Date.today
    customer = route.planning.customer
    position = route.vehicle.store_start
    waypoint_start = (!route.vehicle.store_start.nil? && !route.vehicle.store_start.lat.nil? && !route.vehicle.store_start.lng.nil?) ? [[
        route.vehicle.store_start.lat,
        route.vehicle.store_start.lng,
        '',
        route.vehicle.store_start.name
      ]] : []
    waypoint_stop = (!route.vehicle.store_stop.nil? && !route.vehicle.store_stop.lat.nil? && !route.vehicle.store_stop.lng.nil?) ? [[
        route.vehicle.store_stop.lat,
        route.vehicle.store_stop.lng,
        '',
        route.vehicle.store_stop.name
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
          stop.is_a?(StopDestination) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil) : nil,
          stop.name,
          stop.comment
        ]
      }
    waypoints = (waypoint_start + waypoints.compact + waypoint_stop).map{ |l|
        description = l[2..-1].select{ |s| s }.join(' ').strip
        {lat: l[0], lng: l[1], description: description}
      }
    position = route.vehicle.store_stop if !route.vehicle.store_stop.nil? && !route.vehicle.store_stop.lat.nil? && !route.vehicle.store_stop.lng.nil?
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, position, route.vehicle.id, route.ref || route.vehicle.store_stop.name, route.start, waypoints)
  end
end
