class OptimizerTest < ActionController::TestCase
  setup do
    @route = routes(:route_one_one)
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      Routers::Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
        Ort.stub_any_instance(:optimize, lambda{ |optimize_time, soft_upper_bound, capacity, matrix, time_window, rest_window, time_threshold| (0..(matrix.size-1)).to_a }) do
          yield
        end
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
