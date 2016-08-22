require 'test_helper'
require 'routers/osrm'

class PlanningTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      yield
    end
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

    o.set_routes({'route_one_one' => {visits: [[visits(:visit_one)]]}})
    assert o.routes[1].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should not set_routes for tags' do
    o = plannings(:planning_one)
    o.tags << tags(:tag_two)

    o.set_routes({'route_one_one' => {visits: [[visits(:visit_one)]]}})
    assert_not o.routes[1].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should set_routes with ref_vehicle' do
    o = plannings(:planning_one)

    o.set_routes({'route_one_one' => {visits: [[visits(:visit_one)]], ref_vehicle: vehicles(:vehicle_one).ref}})
    assert o.routes[2].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
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
    o.zonings = []
    assert_difference('Stop.count', 0) do
      # route_zero has not any vehicle_usage => stop will be affected to another route
      o.automatic_insert(o.routes.find{ |ro| ro.ref == 'route_zero' }.stops[0])
      o.save!
    end
    o.reload
    assert_equal 3, o.routes.size
    assert_equal 0, o.routes.find{ |ro| ro.ref == 'route_zero' }.stops.size
    assert_equal 4 + 1 + 1, o.routes.select{ |ro| ro.ref != 'route_zero' }.collect{ |r| r.stops.size }.inject(:+)
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
end

class PlanningTestError < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not compute because of router error' do
    o = plannings(:planning_one)
    Routers::Osrm.stub_any_instance(:compute, []) do
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
    Routers::Osrm.stub_any_instance(:compute, lambda{ |*a| raise }) do
      assert_no_difference('Stop.count') do
        o.zoning_out_of_date = true
        assert_raises(RuntimeError) do
          o.compute
        end
      end
    end
  end
end
