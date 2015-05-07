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
        street: stop.street,
        city: stop.city,
        postalcode: stop.postalcode,
        country: stop.country || customer.default_country,
        lat: stop.lat,
        lng: stop.lng,
        ref: stop.ref,
        name: stop.name,
        id: stop.base_id,
        description: [
          stop.name,
          stop.base_ref,
          stop.is_a?(StopDestination) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil) : nil,
          stop.is_a?(StopDestination) ? (stop.destination.take_over ? '(' + stop.destination.take_over.strftime('%H:%M:%S') + ')' : nil) : route.vehicle.rest_duration.strftime("%H:%M:%S"),
          stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
          stop.detail,
          stop.comment,
        ].select{ |s| s }.join(' ').strip,
        time: stop.time,
        updated_at: stop.base_updated_at,
      }
    }

    MasternautWs.createJobRoute(customer.masternaut_user, customer.masternaut_password, route.vehicle.masternaut_ref, order_id_base, route.ref || route.vehicle.name, route.planning.date || Date.today, route.start, route.end, waypoints)
  end
end
