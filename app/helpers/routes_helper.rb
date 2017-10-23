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
      {
        id: id,
        quantity: Route.localize_numeric_value(v) + (vehicle && vehicle.default_capacities[id] ? '/' + Route.localize_numeric_value(vehicle.default_capacities[id]) : '') + (unit.label ? "\u202F" + unit.label : ''),
        unit_icon: unit.default_icon
      } if unit
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
end
