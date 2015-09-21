# Copyright © Mapotempo, 2014-2015
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
require 'osrm'

class RouterOsrm < Router
  validates :url, presence: true

  def trace(speed_multiplicator, lat1, lng1, lat2, lng2)
    distance, time, trace = Mapotempo::Application.config.osrm.compute(url, lat1, lng1, lat2, lng2)
    time *= 1.0 / speed_multiplicator
    [distance, time, trace]
  end

  def matrix(row, column, speed_multiplicator, &block)
    time_multiplicator = 1.0 / speed_multiplicator
    row, column = pack_vector(row, column)
    vector = row != column ? row + column : row
    matrix = Mapotempo::Application.config.osrm.matrix(url, vector)
    if row != column
      matrix = matrix[row.size..-1].collect{ |row|
        row[0..row.size - 1]
      }
    end
    matrix = unpack_vector(row, column, matrix)
    matrix.map{ |row|
      row.map{ |v| [v, v * time_multiplicator] }
    }
  end

  def isochrone?
    !url_isochrone.nil?
  end

  def isochrone(lat, lng, size)
    Mapotempo::Application.config.osrm.isochrone(url_isochrone, lat, lng, size)
  end
end
