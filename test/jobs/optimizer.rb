class OptimizerTest < ActionController::TestCase
  def around
    @route = routes(:route_one_one)

    Routers::Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      Routers::Osrm.stub_any_instance(:optimize, lambda{ |capacity, matrix, time_window, time_threshold| (0..(matrix.size-1)).to_a }) do
        yield
      end
    end
  end

  test 'should optimize' do
    Optimizer.optimize(@route.planning, @route)
    @route.stops.each{ |stop|
      assert stop.active
    }
  end
end
