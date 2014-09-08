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
      TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, stop, order_id_base+stop.id.to_s, description)
    }
  end

  def self.export_route_as_waypoints(customer, route)
    waypoints = route.stops.collect{ |stop|
      description = [
        '',
        stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
        stop.destination.name,
        stop.destination.comment
      ].select{ |s| s }.join(' ').strip
      {lat: stop.destination.lat, lng: stop.destination.lng, description: description}
    }
    order_id_base = Time.now.strftime("%Y%m%d%H%M%S")
    TomtomWebfleet.sendDestinationOrder(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, route.vehicle.tomtom_id, route.stops[-1], order_id_base+route.vehicle.id.to_s, route.stops[-1].destination.name, waypoints)
  end
end
