require 'ort'
require 'matrix_job'

class Optimizer

  def self.optimize(customer, planning, route)
    if Mapotempo::Application.config.delayed_job_use
      if customer.job_matrix
        # Customer already run an optimization
        false
      else
        customer.job_matrix = Delayed::Job.enqueue(MatrixJob.new(planning.id, route.id))
      end
    else
      optimum = Ort.optimize(route.vehicle.capacity, route.matrix)
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
