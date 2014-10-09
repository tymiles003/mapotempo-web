require 'test_helper'

class RouteTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    def Trace.compute(url, from_lat, from_lng, to_lat, to_lng)
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
    o.planning.tags.clear
    o.stops.clear
    o.save!
    assert_difference('Stop.count', Destination.all.size) do
      o.default_stops
      o.save!
    end
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
    assert_equal o.stops.size + 1, o.distance
  end

  test "should compute empty" do
    o = routes(:route_one)
    assert o.stops.size > 1
    o.compute
    assert_equal o.stops.size + 1, o.distance

    o.stops.each{ |stop|
      stop.active = false
    }

    o.compute
    assert_equal 1, o.distance
  end

  test "should set destinations" do
    o = routes(:route_one)
    o.stops.clear
    assert_difference('Stop.count', 1) do
      o.set_destinations([[destinations(:destination_two), true]])
      o.save!
    end
  end

  test "should add" do
    o = routes(:route_zero)
    o.add(destinations(:destination_two))
    o.save!
    o.reload
    assert o.stops.collect(&:destination).include?(destinations(:destination_two))
  end

  test "should add index" do
    o = routes(:route_one)
    o.add(destinations(:destination_two), 1)
    o.save!
    o.stops.reload
    assert_equal destinations(:destination_two), o.stops.find{ |s| s.destination.name == 'destination_two' }.destination
  end

  test "should not add without index" do
    o = routes(:route_one)
    assert_raises(RuntimeError) {
      o.add(destinations(:destination_two))
    }
  end

  test "should remove" do
    o = routes(:route_one)
    assert_difference('Stop.count', -1) do
      o.remove(destinations(:destination_two))
      o.save!
    end
  end

  test "should sum_out_of_window" do
    o = routes(:route_one)

    o.stops.each { |s|
      s.destination.open = s.destination.close = nil
      s.destination.save
    }
    o.vehicle.open = Time.new(2000, 01, 01, 00, 00, 00, "+00:00")
    o.planning.customer.take_over = Time.new(2000, 01, 01, 00, 00, 00, "+00:00")
    o.planning.customer.save

    assert_equal 0, o.sum_out_of_window

    o.stops[1].destination.open = Time.new(2000, 01, 01, 00, 00, 00, "+00:00")
    o.stops[1].destination.close = Time.new(2000, 01, 01, 00, 00, 00, "+00:00")
    o.stops[1].destination.save
    assert_equal 30, o.sum_out_of_window
  end

  test "should matrix_size" do
    o = routes(:route_one)

    assert_equal o.stops.size + 2, o.matrix_size

    o.stops[1].active = false
    assert_equal o.stops.size + 2 - 1, o.matrix_size
  end

  test "should chnage active" do
    o = routes(:route_one)

    assert_equal 2, o.size_active
    o.active(:none)
    assert_equal 0, o.size_active
    o.active(:all)
    assert_equal 2, o.size_active
    o.stops[0].active = false
    assert_equal 1, o.size_active
    o.active(:foo_bar)
    assert_equal 1, o.size_active
  end

  test "move stop inside route" do
    o = routes(:route_one)
    s = o.stops[1]
    assert s.index = 2
    o.move_destination(s.destination, 1)
    assert s.index = 1
  end

  test "move stop to affected route" do
    o = routes(:route_zero)
    s = o.stops[0]
    assert_not s.index
    routes(:route_one).move_destination(s.destination, 1)
  end

  test "move stop o unaffected route" do
    o = routes(:route_one)
    s = o.stops[1]
    routes(:route_zero).move_destination(s.destination, 1)
  end
end
