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
    planning.vehicle_usage_set.vehicle_usages.active.map(&:vehicle).map{ |vehicle| { id: vehicle.id, text: vehicle.name, color: vehicle.color, available_position: vehicle.customer.device.available_position? && vehicle.vehicle_usages.detect{ |item| item.vehicle_usage_set == @planning.vehicle_usage_set }.active? } }
  end

  def planning_vehicles_usages_map(planning)
    planning.vehicle_usage_set.vehicle_usages.active.each_with_object({}) do |vehicle_usage, hash|
      hash[vehicle_usage.vehicle_id] = vehicle_usage.vehicle.slice(:name, :color, :capacities).merge(vehicle_usage_id: vehicle_usage.id, vehicle_id: vehicle_usage.vehicle_id)
    end
  end
end
