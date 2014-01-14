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
require 'ort'

class MatrixJob < Struct.new(:planning_id, :route_id)
  def perform
    Delayed::Worker.logger.info "MatrixJob planning_id=#{planning_id} perform"
    route = Route.where(id: route_id, planning_id: planning_id).first
    customer = route.planning.customer
    count = route.stops.size
    i = 0
    matrix = route.matrix {
      i += 1
      if i % 50 == 0
        customer.job_matrix.progress = Integer(i * 100 / count)
        customer.job_matrix.save
        Delayed::Worker.logger.info "MatrixJob planning_id=#{planning_id} #{customer.job_matrix.progress}%"
      end
    }
    customer.job_matrix.progress = 100
    customer.job_matrix.save
    Delayed::Worker.logger.info "MatrixJob planning_id=#{planning_id} #{customer.job_matrix.progress}%"

    # Optimize
    tws = route.stops[0..-2].select{ |stop| stop.active }.collect{ |stop|
      open = stop.destination.open ? Integer(stop.destination.open - route.vehicle.open) : nil
      close = stop.destination.close ? Integer(stop.destination.close - route.vehicle.open) : nil
      if open && close && open > close
        close = open
      end
      take_over = customer.take_over ? Integer(customer.take_over.seconds_since_midnight) : 0
      [open, close, take_over]
    }
    optimum = Ort.optimize(route.vehicle.capacity, matrix, tws)
    if optimum
      route.order(optimum)
      route.save && route.reload # Refresh stops order
      route.planning.compute
      route.planning.save
      customer.save
    end
  end
end
