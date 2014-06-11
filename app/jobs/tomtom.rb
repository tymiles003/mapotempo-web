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
    lang = 'fr' # FIXME

    TomtomWebfleet.clearOrdersExtern(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, lang, route.vehicle.tomtom_id)

    route.stops.each{ |stop|
      description = [
        '',
        stop.destination.name,
        stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
        stop.destination.open || stop.destination.close ? (stop.destination.open ? stop.destination.open : '') + '-' + (stop.destination.close ? stop.destination.close : '') : nil,
        stop.destination.detail,
        stop.destination.comment,
      ].select{ |s| s }.join(' ').strip
      TomtomWebfleet.sendDestinationOrderExtern(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, lang, route.vehicle.tomtom_id, stop, stop.id, description)
    }
  end

  def self.export_route_as_waypoints(customer, route)
    lang = 'fr' # FIXME

    TomtomWebfleet.clearOrdersExtern(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, lang, route.vehicle.tomtom_id)

    waypoints = route.stops.collect{ |stop|
      description = [
        '',
        stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
        stop.destination.name,
        stop.destination.comment
      ].select{ |s| s }.join(' ').strip
      {lat: stop.destination.lat, lng: stop.destination.lng, description: description}
    }
    TomtomWebfleet.sendDestinationOrderExtern(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, lang, route.vehicle.tomtom_id, route.stops[-1], route.vehicle.id, route.stops[-1].destination.name, waypoints)
  end
end
