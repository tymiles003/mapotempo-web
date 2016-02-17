# Copyright © Mapotempo, 2013-2015
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

class OptimizerJob < Struct.new(:planning_id, :route_id)
  @@optimize_time = Mapotempo::Application.config.optimize_time
  @@soft_upper_bound = Mapotempo::Application.config.optimize_soft_upper_bound

  def before(job)
    @job = job
  end

  def perform
    Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} perform"
    routes = route_id ? Route.where(id: route_id, planning_id: planning_id) : Route.where(planning_id: planning_id)
    optimize_time = routes[0].planning.customer.optimization_time || @@optimize_time
    soft_upper_bound = routes[0].planning.customer.optimization_soft_upper_bound || @@soft_upper_bound

    route_actives = routes.select{ |route|
      route.vehicle_usage && route.size_active > 1
    }
    routes_size = route_actives.length
    route_actives.each_with_index { |route, routes_count|
      route = Route.find(route.id) # IMPORTANT: Lower Delayed Job Memory Usage
      customer = route.planning.customer
      i = ii = 0
      optimum = route.optimize(Proc.new { |computed, count|
        i += computed
        if i > ii + 50
          @job.progress = "#{i * 100 / count};0;" + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
          @job.save
          Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
          ii = i
        end
      }) { |matrix, tws, rest_tws|
        @job.progress = '100;0;' + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
        @job.save
        Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"

        # Optimize
        @job.progress = "100;#{optimize_time * 1000}ms#{routes_count};" + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
        @job.save
        Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
        optimum = Mapotempo::Application.config.optimize.optimize(optimize_time * 1000, soft_upper_bound, route.vehicle_usage.vehicle.capacity, matrix, tws, rest_tws, route.planning.customer.optimization_cluster_size || Mapotempo::Application.config.optimize_cluster_size)
        @job.progress = '100;100;' + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
        @job.save
        Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
        optimum
      }

      # Apply result
      if optimum
        route.order(optimum)
        route.save && route.reload # Refresh stops order
        route.compute
        route.save # Because route is not saved below
        route.planning.save
      end
    }
  end
end
