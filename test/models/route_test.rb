require 'test_helper'

class RouteTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    def Trace.compute(from_lat, from_lng, to_lat, to_lng)
      [1, 1, "trace"]
    end
  end

  test "should not save" do
    o = Route.new
    assert_not o.save, "Saved without required fields"
  end

  test "should dup" do
    o = routes(:route_one)
    oo = o.amoeba_dup
    assert_equal oo, oo.stops[0].route
  end

  test "should default_stops" do
    o = routes(:route_one)
    o.planning.tags = []
    o.stops.clear
    o.default_stops
    assert_equal Destination.all.size - 1, o.stops.size
  end

  test "should default_store" do
    o = routes(:route_one)
    o.stops.clear
    o.default_store
    assert_equal 2, o.stops.size
  end

  test "should compute" do
    o = routes(:route_one)
    o.out_of_date = true
    o.distance = o.emission = o.start = o.end = nil
    o.compute
    assert_not o.out_of_date
    assert o.distance
    assert o.emission
    assert o.start
    assert o.end
    assert_equal o.stops.size - 1, o.distance
  end

  test "should compute empty" do
    o = routes(:route_one)
    assert o.stops.size > 3
    o.compute
    assert_equal o.stops.size - 1, o.distance

    o.stops[1..-2].each{ |stop|
      stop.active = false
    }

    o.compute
    assert_equal 1, o.distance
  end
end
