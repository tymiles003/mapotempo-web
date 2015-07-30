# Copyright © Mapotempo, 2015
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
    customer = route.planning.customer

    store = route.vehicle.store_start
    staff = {
      id: route.vehicle.name,
      name: route.vehicle.name,
      street: store.street,
      postalcode: store.postalcode,
      city: store.city,
    }

    date = route.planning.date || Date.today
    planning_id_base = date.strftime('%y%m%d')
    base_time = date.to_time
    position = route.vehicle.store_start
    waypoints = route.stops.select(&:active).collect{ |stop|
      position = stop.position? ? stop : position
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
          ].select{ |s| s }.join(' ').strip
        },
        planning: {
          id: planning_id_base + '_' + stop.base_id.to_s,
          staff_id: route.vehicle.name,
          destination_id: stop.base_id,
          comment: [
            stop.is_a?(StopDestination) ? (route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil) : nil,
          ].select{ |s| s }.join(' ').strip,
          start: base_time + stop.time.seconds_since_midnight.seconds,
          end: base_time + (stop.time.seconds_since_midnight + stop.duration).seconds,
        }
      }
    }
    customer = route.planning.customer
    AlyacomApi.createJobRoute(customer.alyacom_association, date, staff, waypoints)
  end
end
