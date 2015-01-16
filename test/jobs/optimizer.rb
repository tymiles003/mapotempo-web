class OptimizerTest < ActionController::TestCase
  setup do
    def Trace.compute(url, from_lat, from_lng, to_lat, to_lng)
      [1000, 60, "trace"]
    end

    def Ort.optimize(capacity, matrix, time_window, time_threshold)
      (0..(matrix.size-1)).to_a
    end

    @route = routes(:route_one)
  end

  test "should optimize" do
    Optimizer.optimize(@route.planning, @route)
    @route.stops.each{ |stop|
      assert stop.active
    }
  end
end
