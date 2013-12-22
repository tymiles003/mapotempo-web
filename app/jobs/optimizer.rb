require 'ort'
require 'matrix_job'

class Optimizer

  def self.optimize(customer, planning, route)
    if route.size <= 1
        # Nothing to optimize
        true
    elsif Mapotempo::Application.config.delayed_job_use
      if customer.job_matrix
        # Customer already run an optimization
        false
      else
        customer.job_matrix = Delayed::Job.enqueue(MatrixJob.new(planning.id, route.id))
      end
    else
      tws = route.stops[0..-2].select{ |stop| stop.active }.collect{ |stop|
        [
          (stop.destination.open ? stop.destination.open.min * 60 + stop.destination.open.hour * 60 * 60 + (customer.take_over or 0): nil),
          (stop.destination.close ? stop.destination.close.min * 60 + stop.destination.close.hour * 60 * 60 : nil)
        ]
      }
      optimum = Ort.optimize(route.vehicle.capacity, route.matrix, tws)
      if optimum
        route.order(optimum)
        route.save && route.reload # Refresh stops order
        planning.compute
        planning.save
      else
        false
      end
    end
  end

end
