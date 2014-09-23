# Copyright © Mapotempo, 2014
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

  def self.export_route_as_orders(customer, route)
    order_id_base = Time.now.strftime("%Y%m%d%H%M%S")
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, route.vehicle.store_start, order_id_base+'_0', route.vehicle.store_start.name, route.start)
    route.stops.each{ |stop|
      description = [
        '',
        stop.destination.name,
        stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
        stop.destination.take_over ? '(' + stop.destination.take_over.strftime('%H:%M:%S') + ')' : nil,
        stop.destination.open || stop.destination.close ? (stop.destination.open ? stop.destination.open.strftime('%H:%M') : '') + '-' + (stop.destination.close ? stop.destination.close.strftime('%H:%M') : '') : nil,
        stop.destination.detail,
        stop.destination.comment,
      ].select{ |s| s }.join(' ').strip
      TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, stop.destination, order_id_base+stop.id.to_s, description, stop.time)
    }
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, route.vehicle.store_stop, order_id_base+'_1', route.vehicle.store_stop.name, route.end)
  end

  def self.export_route_as_waypoints(customer, route)
    waypoints = ([[
        route.vehicle.store_start.lat,
        route.vehicle.store_start.lng,
        '',
        route.vehicle.store_start.name
      ]] + route.stops.collect{ |stop|
        description = [
          stop.destination.lat,
          stop.destination.lng,
          '',
          stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
          stop.destination.name,
          stop.destination.comment
        ]
      } + [[
        route.vehicle.store_stop.lat,
        route.vehicle.store_stop.lng,
        '',
        route.vehicle.store_stop.name
      ]]).map{ |l|
        description = l.select{ |s| s }.join(' ').strip
        {lat: l[0], lng: l[1], description: description}
      }
    order_id_base = Time.now.strftime("%Y%m%d%H%M%S")
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, route.vehicle.store_stop, order_id_base+route.vehicle.id.to_s, route.vehicle.store_stop.name, route.end, waypoints)
  end
end
