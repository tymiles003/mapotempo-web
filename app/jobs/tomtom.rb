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
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, route.vehicle.store_start, -1, route.vehicle.store_start.name, route.start)
    route.stops.select(&:active).each{ |stop|
      description = [
        '',
        stop.destination.name,
        route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
        stop.is_a?(StopDestination) ? stop.destination.take_over ? '(' + stop.destination.take_over.strftime('%H:%M:%S') + ')' : nil : nil,
        stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
        stop.destination.detail,
        stop.destination.comment,
      ].select{ |s| s }.join(' ').strip
      TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, stop.destination, stop.id, description, stop.time)
    }
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, route.vehicle.store_stop, -2, route.vehicle.store_stop.name, route.start)
  end

  def self.export_route_as_waypoints(route)
    date = route.planning.date || Date.today
    customer = route.planning.customer
    waypoints = ([[
        route.vehicle.store_start.lat,
        route.vehicle.store_start.lng,
        '',
        route.vehicle.store_start.name
      ]] + route.stops.select(&:active).collect{ |stop|
        [
          stop.lat,
          stop.lng,
          '',
          route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
          stop.destination.name,
          stop.destination.comment
        ]
      } + [[
        route.vehicle.store_stop.lat,
        route.vehicle.store_stop.lng,
        '',
        route.vehicle.store_stop.name
      ]]).map{ |l|
        description = l[2..-1].select{ |s| s }.join(' ').strip
        {lat: l[0], lng: l[1], description: description}
      }
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, date, route.vehicle.store_stop, route.vehicle.id, route.vehicle.store_stop.name, route.start, waypoints)
  end
end
