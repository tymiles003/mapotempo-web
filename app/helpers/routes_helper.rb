# Copyright © Mapotempo, 2013-2016
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
module RoutesHelper
  def display_start_time(route)
    route.start + route.service_time_start_value if route.start && route.service_time_start_value
  end

  def display_end_time(route)
    route.end - route.service_time_end_value if route.end && route.service_time_end_value
  end

  def route_quantities(route)
    vehicle = route.vehicle_usage.try(:vehicle)
    route.quantities.select{ |_k, v|
      v > 0
    }.collect{ |id, v|
      unit = route.planning.customer.deliverable_units.find{ |du| du.id == id }
      next unless unit
      q = number_with_precision(v, precision: 2, delimiter: I18n.t('number.format.delimiter'), strip_insignificant_zeros: true).to_s
      q += '/' + number_with_precision(vehicle.default_capacities[id], precision: 2, delimiter: I18n.t('number.format.delimiter'), strip_insignificant_zeros: true).to_s if vehicle && vehicle.default_capacities[id]
      q += "\u202F" + unit.label if unit.label
      {
        id: id,
        quantity: q,
        unit_icon: unit.default_icon
      }
    }.compact
  end

  def export_column_titles(columns)
    columns.map{ |c|
      if (m = /^(.+)\[(.*)\]$/.match(c))
        I18n.t('plannings.export_file.' + m[1]) + '[' + m[2] + ']'
      else
        I18n.t('plannings.export_file.' + c.to_s)
      end
    }
  end

  def route_devices(devices, route)
    route_devices_hash = {}
    devices_route = route.vehicle_usage.vehicle.devices

    devices_route.each do |key, value|
      if devices.has_key?(key)
        match_device = devices[key].select{ |dv| dv[:id] == value }.first
        route_devices_hash[key] = match_device unless match_device.empty?
      else
        route_devices_hash[key] = value
      end
    end
    route_devices_hash
  end
end
