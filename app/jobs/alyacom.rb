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

    base_date = route.planning.order_array_id ? route.planning.order_array.base_date + route.planning.order_array_shift : Date.today
    planning_id_base = base_date.strftime('%y%m%d')
    base_time = base_date.to_time
    waypoints = route.stops.select(&:active).collect{ |stop|
      take_over = stop.destination.take_over ? stop.destination.take_over : customer.take_over
      take_over = take_over ? take_over.seconds_since_midnight : 0
      destination = stop.destination

      {
        user: {
          id: destination.id,
          name: destination.name,
          street: destination.street,
          postalcode: destination.postalcode,
          city: destination.city,
          detail: destination.detail,
          comment: [
            stop.destination.ref,
            stop.destination.open || stop.destination.close ? (stop.destination.open ? stop.destination.open.strftime('%H:%M') : '') + '-' + (stop.destination.close ? stop.destination.close.strftime('%H:%M') : '') : nil,
            stop.destination.comment,
          ].select{ |s| s }.join(' ').strip
        },
        planning: {
          id: planning_id_base + '_' + stop.destination.id.to_s,
          staff_id: route.vehicle.name,
          destination_id: stop.destination.id,
          comment: [
            route.planning.customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.destination.quantity && stop.destination.quantity > 1 ? "x#{stop.destination.quantity}" : nil,
          ].select{ |s| s }.join(' ').strip,
          start: base_time + stop.time.seconds_since_midnight.seconds,
          end: base_time + (stop.time.seconds_since_midnight + take_over).seconds,
        }
      }
    }
    customer = route.planning.customer
    AlyacomApi.createJobRoute(customer.alyacom_association, base_date, staff, waypoints)
  end
end
