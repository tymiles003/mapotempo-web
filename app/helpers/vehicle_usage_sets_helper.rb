# Copyright © Mapotempo, 2016
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
module VehicleUsageSetsHelper

  def vehicle_usage_set_service_time vehicle_usage_set
    capture do
      if vehicle_usage_set.service_time_start
        concat l(vehicle_usage_set.service_time_start, format: :hour_minute)
      else
        concat span_tag('--')
      end
      concat span_tag(' / ')
      if vehicle_usage_set.service_time_end
        concat l(vehicle_usage_set.service_time_end, format: :hour_minute)
      else
        concat span_tag('--')
      end
    end
  end

end
