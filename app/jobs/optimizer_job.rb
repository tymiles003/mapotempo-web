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
  @@optimize_time_force = Mapotempo::Application.config.optimize_time_force
  @@stop_soft_upper_bound = Mapotempo::Application.config.optimize_stop_soft_upper_bound
  @@vehicle_soft_upper_bound = Mapotempo::Application.config.optimize_vehicle_soft_upper_bound
  @@optimization_cluster_size = Mapotempo::Application.config.optimize_cluster_size

  def before(job)
    @job = job
  end

  def perform
    Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} perform"
    planning = Planning.where(id: planning_id).first!
    routes = planning.routes.select{ |r|
      (route_id && r.id == route_id) || (!route_id && !global && r.vehicle_usage && r.size_active > 1) || (!route_id && global)
    }.reject(&:locked)
    optimize_time = planning.customer.optimization_time || @@optimize_time

    bars = Array.new(2, 0)
    optimum = !routes.empty? && planning.optimize(routes, global) { |positions, services, vehicles|
      optimum = Mapotempo::Application.config.optimize.optimize(
        positions, services, vehicles,
        optimize_time: @@optimize_time_force || (optimize_time ? optimize_time * 1000 : nil),
        stop_soft_upper_bound: planning.customer.optimization_stop_soft_upper_bound || @@stop_soft_upper_bound,
        vehicle_soft_upper_bound: planning.customer.optimization_vehicle_soft_upper_bound || @@vehicle_soft_upper_bound,
        cluster_threshold: planning.customer.optimization_cluster_size || @@optimization_cluster_size
      ) { |bar, computed, count|
          if bar
            if computed
              (0..bar).to_a.each{ |i| bars[i] = (computed - 1) * 100 / count }
            else
              (0..(bar-1)).to_a.each{ |i| bars[i] = 100 } if bar > 0
              bars[bar] = bar == 1 && (@@optimize_time_force || planning.customer.optimization_time) ? "#{(@@optimize_time_force || optimize_time) * 1000}ms0" : -1
            end
          end
          @job.progress = bars.join(';') + ';'
          @job.save
          Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{@job.progress}"
        }
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
      planning.save!
    end
  rescue => e
    puts e.message
    puts e.backtrace.join("\n")
    raise e
  end
end
