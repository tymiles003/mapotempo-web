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
  def trace(speed_multiplicator, lat1, lng1, lat2, lng2, dimension = :time, options = {})
    trace_batch(speed_multiplicator, [[lat1, lng1, lat2, lng2]], dimension, options)
  end

  def trace_batch(speed_multiplicator, segments, dimension = :time, options = {})
    Mapotempo::Application.config.router_wrapper.compute_batch(url_time, mode, dimension, segments, sanitize_options(options, speed_multiplicator: speed_multiplicator))
  end

  def matrix(row, column, speed_multiplicator, dimension = :time, options = {}, &block)
    block.call(nil, nil) if block
    Mapotempo::Application.config.router_wrapper.matrix(url_time, mode, [dimension], row, column, sanitize_options(options, speed_multiplicator: speed_multiplicator))[0].map{ |row|
      row.map{ |v| [v, v] }
    }
  end

  def compute_isochrone(lat, lng, size, speed_multiplicator, options = {})
    Mapotempo::Application.config.router_wrapper.isoline(url_time, mode, :time, lat, lng, size, sanitize_options(options, speed_multiplicator: speed_multiplicator))
  end

  def compute_isodistance(lat, lng, size, speed_multiplicator, options = {})
    Mapotempo::Application.config.router_wrapper.isoline(url_time, mode, :distance, lat, lng, size, sanitize_options(options, speed_multiplicator: speed_multiplicator))
  end

  private

  def sanitize_options(options, extra_options = {})
    if !avoid_zones? && !speed_multiplicator_zones?
      options.delete(:speed_multiplicator_areas)
      options.delete(:area)
    end

    options.merge(extra_options)
  end
end
