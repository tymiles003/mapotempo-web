require 'test_helper'

class OptimizerTest < ActionController::TestCase
  setup do
    @route = routes(:route_one_one)
  end

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1000, 60, '_ibE_seK_seK_seK'] } } ) do
      Routers::RouterWrapper.stub_any_instance(:matrix, lambda{ |url, mode, dimensions, row, column, options| [Array.new(row.size) { Array.new(column.size, 0) }] }) do
        # return all services in reverse order in first route, rests at the end
        OptimizerWrapper.stub_any_instance(:optimize, lambda { |positions, services, vehicles, options| [[]] + [(services.reverse + vehicles[0][:rests]).collect{ |s| s[:stop_id] }] }) do
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
