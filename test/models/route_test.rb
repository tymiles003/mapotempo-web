require 'test_helper'
require 'routers/osrm'

class RouteTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1, 720, 'trace'] } } ) do
      Routers::RouterWrapper.stub_any_instance(:matrix, lambda{ |url, mode, dimensions, row, column, options| [Array.new(row.size) { Array.new(column.size, 0) }] }) do
        yield
      end
    end
  end

  test 'should not save' do
    o = Route.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should dup' do
    o = routes(:route_one_one)
    oo = o.amoeba_dup
    assert_equal oo, oo.stops[0].route
    oo.save!
  end

  test 'should default_stops' do
    o = routes(:route_one_one)
    o.planning.tags.clear
    o.stops.clear
    o.save!
    assert_difference('Stop.count', Visit.all.size) do
      o.default_stops
      o.save!
    end
  end

  test 'should compute' do
    o = routes(:route_one_one)
    o.distance = o.emission = o.start = o.end = nil
    o.out_of_date = true
    o.compute
    assert_not o.out_of_date
    assert o.distance
    assert o.emission
    assert o.start
    assert o.end
    assert_equal o.stops.size + 1, o.distance
    o.save!
  end

  test 'should compute empty' do
    o = routes(:route_one_one)
    assert o.stops.size > 1
    o.out_of_date = true
    o.compute
    assert_equal o.stops.size + 1, o.distance

    o.stops.each{ |stop|
      stop.active = false
    }

    o.out_of_date = true
    o.compute
    assert_equal 1, o.distance
    o.save!
  end

  test 'should set visits' do
    o = routes(:route_one_one)
    o.stops.clear
    assert_difference('Stop.count', 1) do
      o.set_visits([[visits(:visit_two), true]])
      o.save!
    end
  end

  test 'should add' do
    o = routes(:route_zero_one)
    o.add(visits(:visit_two))
    o.save!
    o.reload
    assert o.stops.collect(&:visit).include?(visits(:visit_two))
  end

  test 'should add index' do
    o = routes(:route_one_one)
    o.add(visits(:visit_two), 1)
    o.save!
    o.stops.reload
    assert_equal visits(:visit_two), o.stops.find{ |s| s.visit.destination.name == 'destination_two' }.visit
  end

  test 'should not add without index' do
    o = routes(:route_one_one)
    assert_raises(RuntimeError) {
      o.add(visits(:visit_two))
    }
  end

  test 'should remove' do
    o = routes(:route_one_one)
    assert_difference('Stop.count', -1) do
      o.remove_visit(visits(:visit_two))
      o.save!
    end
  end

  test 'should sum_out_of_window' do
    o = routes(:route_one_one)

    o.stops.each { |s|
      if s.is_a?(StopVisit)
        s.visit.open1 = s.visit.close1 = nil
        s.visit.open2 = s.visit.close2 = nil
        s.visit.save!
      else
        s.time = s.open1
        s.save!
      end
    }
    o.vehicle_usage.open = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.planning.customer.take_over = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.planning.customer.save!

    assert_equal 0, o.sum_out_of_window

    o.stops[1].visit.open1 = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.stops[1].visit.close1 = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.stops[1].visit.save!
    assert_equal 30, o.sum_out_of_window
  end

  test 'should change active' do
    o = routes(:route_one_one)

    assert_equal 4, o.size_active
    o.active(:none)
    assert_equal 0, o.size_active
    o.active(:all)
    assert_equal 4, o.size_active
    o.stops[0].active = false
    assert_equal 3, o.size_active
    o.active(:foo_bar)
    assert_equal 0, o.size_active

    o.save!
  end

  test 'should reverse stops' do
    o = routes(:route_one_one)
    ids = o.stops.collect(&:id)
    o.reverse_order
    assert_equal ids, o.stops.collect(&:id)
  end

  test 'compute route with impossible path' do
    o = routes(:route_one_one)
    o.stops[1].visit.destination.lat = o.stops[1].visit.destination.lng = 1 # Geocoded
    o.save!
    o.stops[1].distance = o.stops[1].trace = nil
    o.save!
    o.stop_distance = o.stop_trace = nil
    o.save!
    s = o.vehicle_usage.store_stop
    s.lat = s.lng = 1 # Geocoded
    s.save!
    o.out_of_date = true
    o.compute
  end

  test 'should shift departure' do
    o = routes(:route_one_one)

    stops = o.stops.select{ |s| s.is_a?(StopVisit) }
    stops[0].time = '2000-01-01 10:30:00'
    stops[0].visit.open1 = '2000-01-01 11:00:00'
    stops[0].visit.close1 = '2000-01-01 11:30:00'
    stops[1].time = '2000-01-01 11:00:00'
    stops[1].visit.open1 = '2000-01-01 10:00:00'
    stops[1].visit.close1 = '2000-01-01 11:30:00'
    stops[2].time = '2000-01-01 11:30:00'
    stops[2].visit.open1 = '2000-01-01 12:00:00'
    stops[2].visit.close1 = '2000-01-01 14:00:00'

    o.out_of_date = true
    o.compute
    assert_equal '2000-01-01 10:55:27 UTC', o.start.utc.to_s
  end

  test 'should get defautl color' do
    o = routes(:route_one_one)
    o.color = nil

    assert_not_nil o.default_color

    o.color = '#plop'
    assert_equal o.color, o.default_color
  end
end
