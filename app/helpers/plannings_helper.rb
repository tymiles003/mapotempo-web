# Copyright © Mapotempo, 2013-2014
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
module PlanningsHelper
  def planning_vehicles_array(planning)
    planning.vehicle_usage_set.vehicle_usages.active.map(&:vehicle).map{ |vehicle|
      {
        id: vehicle.id,
        text: vehicle.name,
        color: vehicle.color,
        available_position: vehicle.customer.device.available_position?(vehicle) && vehicle.vehicle_usages.detect{ |item| item.vehicle_usage_set == @planning.vehicle_usage_set }.active?
      }
    }
  end

  def planning_vehicles_usages_map(planning)
    planning.vehicle_usage_set.vehicle_usages.active.each_with_object({}) do |vehicle_usage, hash|
      hash[vehicle_usage.vehicle_id] = vehicle_usage.vehicle.slice(:name, :color, :capacities).merge(vehicle_usage_id: vehicle_usage.id, vehicle_id: vehicle_usage.vehicle_id, router_dimension: vehicle_usage.vehicle.default_router_dimension)
    end
  end

  def planning_quantities(planning)
    hashy_map = {}
    planning.routes.each do |route|
      vehicle = route.vehicle_usage.try(:vehicle)
      next if !vehicle

      route.quantities.select{ |_k, v | v > 0 }.each do |id, v|
        unit = route.planning.customer.deliverable_units.find{ |du| du.id == id }
        next if !unit

        if hashy_map.has_key?(unit.id)
          hashy_map[unit.id][:quantity] += v
          hashy_map[unit.id][:capacity] += vehicle.default_capacities[id] || 0
        else
          hashy_map[unit.id] = {
            id: unit.id,
            label: unit.label,
            unit_icon: unit.default_icon,
            quantity: v,
            capacity: vehicle.default_capacities[id] || 0
          }
        end
      end
    end

    hashy_map.to_a.map { |unit|
      unit[1][:quantity] = LocalizedValues.localize_numeric_value(unit[1][:quantity].round(2))
      # Nil if no capacity
      unit[1][:capacity] = unit[1][:capacity] > 0 ? LocalizedValues.localize_numeric_value(unit[1][:capacity].round(2)) : nil
      unit[1]
    }
  end
end
