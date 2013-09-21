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
    optimum = Ort.optimize(1, matrix)
    if optimum
      route.order(optimum)
      route.save && route.reload # Refresh stops order
      route.planning.compute
      route.planning.save
      customer.save
    end
  end
end
