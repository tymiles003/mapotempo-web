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
require 'routers/router_wrapper'

class RouterWrapper < Router
  def trace(speed_multiplicator, lat1, lng1, lat2, lng2, dimension = :time, geometry = true)
    Mapotempo::Application.config.router_wrapper.compute(url_time, mode, lat1, lng1, lat2, lng2, speed_multiplicator, dimension)
  end

  def matrix(row, column, speed_multiplicator, dimension = :time, &block)
    Mapotempo::Application.config.router_wrapper.matrix(url_time, mode, row, column, speed_multiplicator, dimension).map{ |row|
      row.map{ |v| [v, v] }
    }
  end

  def isochrone(lat, lng, size, speed_multiplicator)
    Mapotempo::Application.config.router_wrapper.isoline(url_time, mode, lat, lng, size, speed_multiplicator, :time)
  end

  def isodistance(lat, lng, size, speed_multiplicator)
    Mapotempo::Application.config.router_wrapper.isoline(url_time, mode, lat, lng, size, speed_multiplicator, :distance)
  end
end
