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
        open = stop.destination.open ? Integer(stop.destination.open - route.vehicle.open) : nil
        close = stop.destination.close ? Integer(stop.destination.close - route.vehicle.open) : nil
        if open && close && open > close
          close = open
        end
        take_over = customer.take_over ? Integer(customer.take_over.seconds_since_midnight) : 0
        [open, close, take_over]
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
