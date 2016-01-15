# Copyright © Mapotempo, 2015-2016
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
require 'alyacom_api'

class Alyacom

  def self.export_route(route)
    store = route.vehicle_usage.default_store_start
    staff = {
      id: route.vehicle_usage.vehicle.name,
      name: route.vehicle_usage.vehicle.name,
      street: store && store.street,
      postalcode: store && store.postalcode,
      city: store && store.city,
    }

    date = route.planning.date || Date.today
    planning_id_base = date.strftime('%y%m%d')
    base_time = date.to_time
    position = route.vehicle_usage.default_store_start
    waypoints = route.stops.select(&:active).collect{ |stop|
      position = stop if stop.position?
      if position.nil? || position.lat.nil? || position.lng.nil?
        next
      end
      {
        user: {
          id: stop.base_id,
          name: stop.name,
          street: position.street,
          postalcode: position.postalcode,
          city: position.city,
          detail: stop.detail,
          comment: [
            stop.ref,
            stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
            stop.comment,
          ].compact.join(' ').strip
        },
        planning: {
          id: planning_id_base + '_' + stop.base_id.to_s,
          staff_id: route.vehicle_usage.vehicle.name,
          destination_id: stop.base_id,
          comment: [
            stop.is_a?(StopVisit) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.visit.quantity && stop.visit.quantity > 1 ? "x#{stop.visit.quantity}" : nil) : nil,
          ].compact.join(' ').strip,
          start: base_time + stop.time.seconds_since_midnight.seconds,
          end: base_time + (stop.time.seconds_since_midnight + stop.duration).seconds,
        }
      }
    }.compact
    AlyacomApi.createJobRoute(route.planning.customer.alyacom_association, date, staff, waypoints)
  end
end
