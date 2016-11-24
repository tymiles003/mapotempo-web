require 'test_helper'
require 'routers/router_wrapper'

class D < Struct.new(:lat, :lng, :id, :open1, :close1, :open2, :close2, :duration, :quantity1_1, :quantity1_2, :vehicle_usage)
  def visit
    self
  end
  def route
    Struct.new(:vehicle_usage, :vehicle_usage_id).new(vehicle_usage, vehicle_usage.try(&:id))
  end
end

class PlanningTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1, 1, 'trace'] } } ) do
      Routers::RouterWrapper.stub_any_instance(:matrix, lambda{ |url, mode, dimensions, row, column, options| [Array.new(row.size) { Array.new(column.size, 0) }] }) do
        yield
      end
    end
  end

  # default order, rest at the end
  def optimizer_route(positions, services, vehicles)
    [[]] + [(services + vehicles[0][:rests]).collect{ |s| s[:stop_id] }]
  end

  # return all services in reverse order in first route, rests at the end
  def optimizer_global(positions, services, vehicles)
    [[]] + vehicles.each_with_index.map{ |v, i|
      ((i.zero? ? services.reject{ |s| s[:vehicle_id] } : []) + services.select{ |s| s[:vehicle_id] && s[:vehicle_id] == v[:id] } + v[:rests]).map{ |s|
        s[:stop_id]
      }.reverse
    }
  end

  test 'should not save' do
    o = Planning.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = customers(:customer_one).plannings.build(name: 'plop', vehicle_usage_set: vehicle_usage_sets(:vehicle_usage_set_one), zonings: [zonings(:zoning_one)])
    o.default_routes
    o.save!
  end

  test 'should dup' do
    o = plannings(:planning_one)
    oo = o.duplicate

    assert_equal oo, oo.routes[0].planning
    oo.save!
  end

  test 'should set_routes' do
    o = plannings(:planning_one)

    o.set_routes({'abc' => {visits: [[visits(:visit_one)]]}})
    assert o.routes[1].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should not set_routes for tags' do
    o = plannings(:planning_one)
    o.tags << tags(:tag_two)

    o.set_routes({'abc' => {visits: [[visits(:visit_one)]]}})
    assert_not o.routes[1].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should set_routes with ref_vehicle' do
    o = plannings(:planning_one)

    o.set_routes({'abc' => {visits: [[visits(:visit_one)]], ref_vehicle: vehicles(:vehicle_three).ref}})
    assert o.routes.find{ |r| r.vehicle_usage.try(&:vehicle) == vehicles(:vehicle_three) }.stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should not set_routes for size' do
    o = plannings(:planning_one)

    assert_raises(RuntimeError) {
      o.set_routes(Hash[0.upto(o.routes.size).collect{ |i| ["route#{i}", {visits: [visits(:visit_one)]}] }])
    }
    o.save!
  end

  test 'should vehicle_usage_add' do
    o = plannings(:planning_one)
    assert_difference('Stop.count', 1) do # One StopRest
      assert_difference('Route.count', 1) do
        o.vehicle_usage_add(vehicle_usages(:vehicle_usage_one_three))
        o.save!
      end
    end
  end

  test 'should vehicle_usage_remove' do
    o = plannings(:planning_one)
    assert_difference('Stop.count', -1) do
      assert_difference('Route.count', -1) do
        o.vehicle_usage_remove(vehicle_usages(:vehicle_usage_one_one))
        o.save!
      end
    end
  end

  test 'should visit_add' do
    o = plannings(:planning_one)
    assert_difference('Stop.count') do
      o.visit_add(visits(:visit_two))
      o.save!
    end
  end

  test 'should visit_remove' do
    o = plannings(:planning_one)
    assert_difference('Stop.count', -2) do
      o.visit_remove(visits(:visit_one))
      o.save!
    end
  end

  test 'move stop on same route from inside to start' do
    o = plannings(:planning_one)
    r = o.routes.select{ |route| route == routes(:route_one_one) }.first
    s = r.stops[1]
    assert_equal 2, s.index
    assert_difference('Stop.count', 0) do
      o.move_stop(r, s, 1)
      o.save!
      s.reload
      assert_equal 1, s.index
    end
  end

  test 'move stop on same route from inside to end' do
    o = plannings(:planning_one)
    r = o.routes.select{ |route| route == routes(:route_one_one) }.first
    s = r.stops[1]
    assert_equal 2, s.index
    assert_difference('Stop.count', 0) do
      o.move_stop(r, s, 3)
      o.save!
      s.reload
      assert_equal 3, s.index
    end
  end

  test 'move stop on same route from start to inside' do
    o = plannings(:planning_one)
    r = o.routes.select{ |route| route == routes(:route_one_one) }.first
    s = r.stops[0]
    assert_equal 1, s.index
    assert_difference('Stop.count', 0) do
      o.move_stop(r, s, 2)
      o.save!
      s.reload
      assert_equal 2, s.index
    end
  end

  test 'move stop on same route from end to inside' do
    o = plannings(:planning_one)
    r = o.routes.select{ |route| route == routes(:route_one_one) }.first
    s = r.stops[2]
    assert_equal 3,  s.index
    assert_difference('Stop.count', 0) do
      o.move_stop(r, s, 2)
      o.save!
      s.reload
      assert_equal 2, s.index
    end
  end

  test 'move stop from unaffected to affected route' do
    o = plannings(:planning_one)
    s = o.routes.select{ |route| route == routes(:route_zero_one) }.first.stops[0]
    assert_not s.index
    r = o.routes.select{ |route| route == routes(:route_one_one) }.first
    assert_difference('Stop.count', 0) do
      assert_difference('r.stops.size', 1) do
        o.move_stop(r, s, 1)
        o.save!
      end
    end
  end

  test 'move stop from unaffected to affected route with automatic_insert' do
    o = plannings(:planning_one)
    s = o.routes.select{ |route| route == routes(:route_zero_one) }.first.stops[0]
    assert_not s.index
    r = o.routes.select{ |route| route == routes(:route_one_one) }.first
    assert_difference('Stop.count', 0) do
      assert_difference('r.stops.size', 1) do
        o.move_stop(r, s, nil)
        o.save!
      end
    end
  end

  test 'move stop from affected to affected route' do
    o = plannings(:planning_one)
    s = o.routes.select{ |route| route == routes(:route_one_one) }.first.stops[0]
    assert s.index
    r = o.routes.select{ |route| route == routes(:route_three_one) }.first
    assert_difference('Stop.count', 0) do
      assert_difference('r.stops.size', 1) do
        o.move_stop(r, s, 1)
        o.save!
      end
    end
  end

  test 'move stop to unaffected route' do
    o = plannings(:planning_one)
    s = o.routes.select{ |route| route == routes(:route_one_one) }.first.stops[1]
    assert s.index
    r = o.routes.select{ |route| route == routes(:route_zero_one) }.first
    assert_difference('Stop.count', 0) do
      assert_difference('r.stops.size', 1) do
        o.move_stop(r, s, 1)
        o.save!
      end
    end
  end

  test 'should compute' do
    o = plannings(:planning_one)
    assert_no_difference('Stop.count') do
      o.zoning_out_of_date = true
      o.compute
      o.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert_not r.out_of_date
      }
      assert_not o.zoning_out_of_date
      o.save!
    end
  end

  test 'should compute with non geocoded' do
    o = plannings(:planning_one)
    o.zoning_out_of_date = true
    d0 = o.routes[0].stops[0].visit.destination
    d0.lat = d0.lng = nil
    o.compute
    o.routes.select{ |r| r.vehicle_usage }.each{ |r|
      assert_not r.out_of_date
    }
    assert_not o.zoning_out_of_date
  end

  test 'should out_of_date' do
    o = plannings(:planning_one)
    assert_not o.out_of_date

    o.routes[1].out_of_date = true
    assert o.out_of_date
  end

  test 'should update zoning' do
    o = plannings(:planning_one)
    assert_not o.zoning_out_of_date
    o.zonings = [zonings(:zoning_two)]
    o.save!
    assert_not o.out_of_date
  end

  test 'should automatic insert' do
    o = plannings(:planning_one)
    stops_count = o.routes.collect{ |r| r.stops.size }.inject(:+)
    o.zonings = []
    assert_difference('Stop.count', 0) do
      # route_zero has not any vehicle_usage => stop will be affected to another route
      o.automatic_insert(o.routes.find{ |ro| ro.ref == 'route_zero' }.stops[0])
      o.save!
    end
    o.reload
    assert_equal 3, o.routes.size
    assert_equal 0, o.routes.find{ |ro| ro.ref == 'route_zero' }.stops.size
    assert_equal stops_count, o.routes.select{ |ro| ro.ref != 'route_zero' }.collect{ |r| r.stops.size }.inject(:+)
  end

  test 'should apply orders' do
    o = plannings(:planning_one)
    r = o.routes.find{ |ro| ro.ref == 'route_one' }
    assert r.stops[0].active
    assert r.stops[1].active

    oa = order_arrays(:order_array_one)
    o.apply_orders(oa, 0)
    assert r.stops[0].active
    assert_not r.stops[1].active
    o.save!
  end

  test 'should apply orders and destroy' do
    o = plannings(:planning_one)
    oa = order_arrays(:order_array_one)
    o.apply_orders(oa, 0)
    o.save!
    oa.destroy
    o.save!
  end

  test 'plan with service time' do
    v = vehicle_usages(:vehicle_usage_one_one)
    r = v.routes.take

    # 1st computation, set Stop times
    r.compute
    stop_times = r.stops.map &:time
    route_start = r.start
    route_end = r.end

    # Add Service Time
    v.vehicle_usage_set.update!(
      service_time_start: Time.utc(2000, 1, 1, 0, 0) + 10.minutes,
      service_time_end: Time.utc(2000, 1, 1, 0, 0) + 25.minutes
    )

    # 2nd computation
    r.compute
    stop_times2 = r.stops.map &:time
    route_start2 = r.start
    route_end2 = r.end

    # Make sure time has been added to route start and end, and stops are still in tw
    assert_equal route_start - 10.minutes, route_start2
    assert_equal stop_times[0], stop_times2[0]
    assert_equal route_end + 25.minutes, route_end2

    # Vehicle Usage overrides Service Time values
    v.update!(
      service_time_start: Time.utc(2000, 1, 1, 0, 0) + 50.minutes,
      service_time_end: Time.utc(2000, 1, 1, 0, 0) + 20.minutes
    )

    # 3rd computation
    r.compute
    stop_times3 = r.stops.map &:time
    route_start3 = r.start
    route_end3 = r.end

    # Let's verify route start is minimal, stops are not at same time
    assert_equal '2000-01-01 10:00:00 UTC', route_start3.utc.to_s
    assert_not_equal stop_times[0], stop_times3[0]
    assert_equal route_end + 20.minutes, route_end3

    # First stop should not be out of time window
    assert !r.stops[0].out_of_window

    # Change time window
    r.stops[0].visit.update!(
      open1: v.service_time_start + 5.minutes,
      close1: v.service_time_start + 10.minutes
    )

    # Compute a last time, this stop should be out of time window
    r.compute
    assert r.stops[0].out_of_window
  end

  test 'plan using stores without lat or lng' do
    v = vehicle_usages(:vehicle_usage_one_one)
    r = v.routes.take
    r.planning.customer.stores.update_all lat: nil, lng: nil
    r.compute
    r.stops.sort_by(&:index).each_with_index do |stop, index|
      if index.zero?
        # Can't trace path, store has no lat / lng to start with
        assert_equal 0, stop.distance
        assert_equal '2000-01-01 10:44:25 UTC', stop.time.utc.to_s
        assert stop.trace.nil?
      elsif index == r.stops.length - 1
        assert stop.distance.nil? && stop.trace.nil?
      else
        assert_equal 1.0, stop.distance
        assert_equal 'trace', stop.trace
      end
    end
  end

  test 'validates format of REF field with invalid characters' do
    planning = plannings :planning_one
    assert_raises(ActiveRecord::RecordInvalid) do
      planning.update! ref: "test.abcd"
    end

    assert_equal ["ne doit pas contenir les caractères \".\", \"\\\" ou \"/\""], planning.errors[:ref]
  end

  test 'validates format of REF field with valid characters' do
    planning = plannings :planning_one
    assert planning.update! ref: "testabcd!@\#{$%^&*()_+},;'\"`[]|{}:<>?-=~"
  end

  test 'validates format of REF field with spaces' do
    planning = plannings :planning_one
    assert planning.update! ref: "  test abcd   "
    assert_equal "test abcd", planning.ref
  end

  test 'date format' do
    planning = plannings :planning_one
    planning.update! date: Date.new(2017, 1, 31)
    I18n.locale = :en
    assert_equal '01-31-2017', I18n.l(planning.date.to_time, format: :datepicker)
    I18n.locale = :fr
    assert_equal '31-01-2017', I18n.l(planning.date.to_time, format: :datepicker)
  end

  test 'duplicate should not change zonings outdated flag when initially false' do
    planning = plannings :planning_one
    assert !planning.zoning_out_of_date
    dup_planning = planning.duplicate
    dup_planning.save!
    assert !dup_planning.zoning_out_of_date
  end

  test 'duplicate should not change zonings outdated flag when initially true' do
    planning = plannings :planning_one
    planning.update! zoning_out_of_date: true
    assert planning.zoning_out_of_date
    dup_planning = planning.duplicate
    dup_planning.save!
    assert dup_planning.zoning_out_of_date
  end

  test 'should no amalgamate point at same position' do
    o = routes(:route_one_one)

    positions = [D.new(1,1,1), D.new(2,2,2), D.new(3,3,3)]
    ret = o.planning.send(:amalgamate_stops_same_position, positions, false) { |positions|
      assert_equal 3, positions.size
      pos = positions.sort
      [pos.collect{ |p|
        p[2]
      }]
    }
    assert_equal positions.size, ret[0].size
    assert_equal 1.upto(positions.size).to_a, ret[0]
  end

  test 'should amalgamate point at same position' do
    o = routes(:route_one_one)

    positions = [D.new(1,1,1,nil,nil,nil,nil,0), D.new(2,2,2,nil,nil,nil,nil,0), D.new(2,2,3,nil,nil,nil,nil,0), D.new(3,3,4,nil,nil,nil,nil,0)]
    ret = o.planning.send(:amalgamate_stops_same_position, positions, false) { |positions|
      assert_equal 3, positions.size
      pos = positions.sort
      [pos.collect{ |p|
        p[2]
      }]
    }
    assert_equal positions.size, ret[0].size
    assert_equal 1.upto(positions.size).to_a, ret[0]
  end

  test 'should no amalgamate point at same position, tw' do
    o = routes(:route_one_one)

    positions = [D.new(1,1,1,nil,nil,nil,nil,0), D.new(2,2,2,nil,nil,nil,nil,0), D.new(2,2,3,10,20,nil,nil,0), D.new(3,3,4,nil,nil,nil,nil,0)]
    ret = o.planning.send(:amalgamate_stops_same_position, positions, false) { |positions|
      assert_equal 4, positions.size
      [(1..(positions.size)).to_a]
    }
    assert_equal positions.size, ret[0].size
    assert_equal 1.upto(positions.size).to_a, ret[0]
  end

  test 'should optimize one route with one store rest' do
    o = routes(:route_one_one)
    optim = o.planning.optimize([o], false) { |*a|
      optimizer_route(*a)
    }
    assert_equal [o.stops.collect(&:id)], optim
  end

  test 'should optimize one route with one no-geoloc rest' do
    o = routes(:route_one_one)
    vehicle_usages(:vehicle_usage_one_one).update! store_rest: nil
    vehicle_usage_sets(:vehicle_usage_set_one).update! store_rest: nil
    o.reload
    optim = o.planning.optimize([o], false) { |*a|
      optimizer_route(*a)
    }
    assert_equal [o.stops.collect(&:id)], optim
  end

  test 'should optimize one route without any store' do
    o = routes(:route_one_one)
    vehicle_usages(:vehicle_usage_one_one).update! store_start: nil, store_stop: nil, store_rest: nil
    vehicle_usage_sets(:vehicle_usage_set_one).update! store_start: nil, store_stop: nil, store_rest: nil
    o.reload
    optim = o.planning.optimize([o], false) { |*a|
      optimizer_route(*a)
    }
    assert_equal [o.stops.collect(&:id)], optim
  end

  test 'should optimize one route with none geoloc store' do
    o = routes(:route_three_one)
    optim = o.planning.optimize([o], false) { |*a|
      optimizer_route(*a)
    }
    assert_equal [o.stops.collect(&:id)], optim
  end

  test 'should optimize global planning' do
    o = plannings(:planning_one)
    optim = o.optimize(o.routes, true) { |*a|
      optimizer_global(*a)
    }
    assert_equal 0, optim[0].size
    assert_equal o.routes[2].stops.select{ |s| s.is_a? StopRest }.size, optim[2].size
    assert_equal o.routes.map{ |r| r.stops.size }.reduce(&:+), optim.flatten.size
  end

  test 'should set stops for one route' do
    o = routes(:route_one_one)
    original_order = o.stops.map(&:id)
    o.planning.set_stops([o], [original_order.reverse])
    assert_equal original_order.reverse, o.stops.map(&:id)
    o.planning.save!
    o.reload
    assert_equal original_order.reverse, o.stops.map(&:id)
  end

  test 'should set stops for planning' do
    o = plannings(:planning_one)
    optim = o.optimize(o.routes, true) { |*a|
      optimizer_global(*a)
    }
    o.set_stops(o.routes, optim)
    assert_equal optim, o.routes.map{ |r| r.stops.map(&:id) }
    o.save!
    o.reload
    assert_equal optim, o.routes.map{ |r| r.stops.map(&:id) }
  end

  test 'should set stops with a geoloc rest in unassigned' do
    o = plannings(:planning_one)
    unassigned = o.routes.flat_map{ |r| r.stops.map(&:id) }
    o.set_stops(o.routes, [unassigned] + [[]] * (o.routes.size - 1))
    assert o.routes.flat_map{ |r| r.stops.select{ |s| s.is_a? StopRest }.map{ |s| s.route.vehicle_usage_id } }.compact.size == o.vehicle_usage_set.vehicle_usages.map(&:default_rest_duration?).size
    o.save!
    o.reload
    assert o.routes.flat_map{ |r| r.stops.select{ |s| s.is_a? StopRest }.map{ |s| s.route.vehicle_usage_id } }.compact.size == o.vehicle_usage_set.vehicle_usages.map(&:default_rest_duration?).size
  end
end

class PlanningTestError < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not compute because of router error' do
    o = plannings(:planning_one)
    Routers::RouterWrapper.stub_any_instance(:compute_batch, []) do
      assert_no_difference('Stop.count') do
        o.zoning_out_of_date = true
        o.compute
        o.save!
      end
    end
  end
end

class PlanningTestException < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not compute because of router exception' do
    o = plannings(:planning_one)
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda{ |*a| raise }) do
      assert_no_difference('Stop.count') do
        o.zoning_out_of_date = true
        assert_raises(RuntimeError) do
          o.compute
        end
      end
    end
  end
end
