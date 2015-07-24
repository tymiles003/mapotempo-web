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
require 'masternaut_ws'

class Masternaut

  def self.export_route(route)
    order_id_base = Time.now.to_i.to_s(36) + '_' + route.id.to_s
    customer = route.planning.customer
    waypoints = route.stops.select(&:active).collect{ |stop|
      {
        street: stop.destination.street,
        city: stop.destination.city,
        country: stop.destination.country || customer.default_country,
        postalcode: stop.destination.postalcode,
        lat: stop.destination.lat,
        lng: stop.destination.lng,
        ref: stop.destination.ref,
        name: stop.destination.name,
        id: stop.destination.id,
        description: [
          stop.destination.name,
          stop.destination.ref,
          route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
          stop.destination.take_over ? '(' + stop.destination.take_over.strftime('%H:%M:%S') + ')' : nil,
          stop.destination.open || stop.destination.close ? (stop.destination.open ? stop.destination.open.strftime('%H:%M') : '') + '-' + (stop.destination.close ? stop.destination.close.strftime('%H:%M') : '') : nil,
          stop.destination.detail,
          stop.destination.comment,
        ].select{ |s| s }.join(' ').strip,
        time: stop.time,
        updated_at: stop.destination.updated_at,
      }
    }

    MasternautWs.createJobRoute(customer.masternaut_user, customer.masternaut_password, route.vehicle.masternaut_ref, order_id_base, route.ref || route.vehicle.name, route.planning.date || Date.today, route.start, route.end, waypoints)
  end
end
