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
require 'optim/ort'

class OptimizerJob < Struct.new(:planning_id, :route_id, :global)
  @@optimize_time = Mapotempo::Application.config.optimize_time
  @@soft_upper_bound = Mapotempo::Application.config.optimize_soft_upper_bound

  def before(job)
    @job = job
  end

  def perform
    Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} perform"
    planning = Planning.where(id: planning_id).first!
    routes = planning.routes.select{ |r|
      (route_id && r.id == route_id) || (!route_id && !global && r.vehicle_usage) || (!route_id && global)
    }.reject(&:locked)
    optimize_time = planning.customer.optimization_time || @@optimize_time
    soft_upper_bound = planning.customer.optimization_soft_upper_bound || @@soft_upper_bound

    i = ii = 0
    optimum = planning.optimize(routes, global, Proc.new { |computed, count|
      if computed
        i += computed
        if i > ii + 50
          @job.progress = "#{i * 100 / count};0;"
          @job.save
          Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
          ii = i
        end
      else
        @job.progress = "-1;0;"
        @job.save
      end
    }) { |matrix, services, vehicles, dimension|
      @job.progress = '100;0;'
      @job.save
      Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"

      # Optimize
      @job.progress = "100;" + (planning.customer.optimization_time ? "#{optimize_time * 1000}ms0;" : '-1;')
      @job.save
      Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
      optimum = Mapotempo::Application.config.optimize.optimize(matrix, dimension, services, vehicles, {optimize_time: optimize_time ? optimize_time * 1000 : nil, soft_upper_bound: soft_upper_bound, cluster_threshold: planning.customer.optimization_cluster_size || Mapotempo::Application.config.optimize_cluster_size})
      @job.progress = '100;100;'
      @job.save
      Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
      optimum
    }

    # Apply result
    if optimum
      planning.set_stops(routes, optimum)
      routes.each{ |r|
        r.reload # Refresh stops order
        r.compute if r.vehicle_usage
        r.save!
      }
      planning.reload
      planning.save
    end
  end
end
