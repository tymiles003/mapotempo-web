# Copyright © Mapotempo, 2014-2016
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
    position = route.vehicle_usage.default_store_start
    waypoints = route.stops.select(&:active).collect{ |stop|
      position = stop if stop.position?
      if position.nil? || position.lat.nil? || position.lng.nil?
        next
      end
      {
        street: position.street,
        city: position.city,
        postalcode: position.postalcode,
        country: !position.country.nil? && !position.country.empty? ? country : customer.default_country,
        lat: position.lat,
        lng: position.lng,
        ref: stop.ref,
        name: stop.name,
        id: stop.base_id,
        description: [
          stop.name,
          stop.ref,
          stop.is_a?(StopVisit) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.visit.quantity && stop.visit.quantity > 1 ? "x#{stop.visit.quantity}" : nil) : nil,
          stop.is_a?(StopVisit) ? (stop.visit.take_over ? '(' + stop.visit.take_over.strftime('%H:%M:%S') + ')' : nil) : route.vehicle_usage.default_rest_duration.strftime('%H:%M:%S'),
          stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
          stop.detail,
          stop.comment,
          stop.phone_number,
        ].compact.join(' ').strip,
        time: stop.time,
        updated_at: stop.base_updated_at,
      }
    }.compact

    if !position.nil? && !position.lat.nil? && !position.lng.nil?
      MasternautWs.createJobRoute(customer.masternaut_user, customer.masternaut_password, route.vehicle_usage.vehicle.masternaut_ref, order_id_base, route.ref || route.vehicle_usage.vehicle.name, route.planning.date || Date.today, route.start, route.end, waypoints)
    end
  end
end
