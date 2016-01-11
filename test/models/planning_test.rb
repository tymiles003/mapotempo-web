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
    o = customers(:customer_one).plannings.build(name: 'plop', vehicle_usage_set: vehicle_usage_sets(:vehicle_usage_set_one), zoning: zonings(:zoning_one))
    o.default_routes
    o.save!
  end

  test 'should dup' do
    o = plannings(:planning_one)
    oo = o.amoeba_dup

    assert_equal oo, oo.routes[0].planning
    oo.save!
  end

  test 'should set_visits' do
    o = plannings(:planning_one)

    o.set_visits({'route_one_one' => [[visits(:visit_one)]]})
    assert o.routes[1].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should not set_visits for tags' do
    o = plannings(:planning_one)
    o.tags << tags(:tag_two)

    o.set_visits({'route_one_one' => [[visits(:visit_one)]]})
    assert_not o.routes[1].stops.select{ |stop| stop.is_a?(StopVisit) }.collect(&:visit).include?(visits(:visit_one))
    o.save!
  end

  test 'should not set_visits for size' do
    o = plannings(:planning_one)

    assert_raises(RuntimeError) {
      o.set_visits(Hash[0.upto(o.routes.size).collect{ |i| ["route#{i}", [visits(:visit_one)]] }])
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

  test 'should compute' do
    o = plannings(:planning_one)
    o.zoning_out_of_date = true
    o.compute
    o.routes.select{ |r| r.vehicle_usage }.each{ |r|
      assert_not r.out_of_date
    }
    assert_not o.zoning_out_of_date
    o.save!
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
    o.zoning = zonings(:zoning_two)
    o.save!
    assert_not o.out_of_date
  end

  test 'should automatic insert' do
    o = plannings(:planning_one)
    o.zoning = nil
    assert_equal 3, o.routes.size
    assert_equal 1, o.routes.find{ |ro| ro.ref == 'route_zero' }.stops.size
    assert_equal 4, o.routes.find{ |ro| ro.ref == 'route_one' }.stops.size
    assert_equal 1, o.routes.find{ |ro| ro.ref == 'route_three' }.stops.size
    assert_difference('Stop.count', 0) do
      # route_zero has not any vehicle_usage => stop will be affected to another route
      o.automatic_insert(o.routes.find{ |ro| ro.ref == 'route_zero' }.stops[0])
      o.save!
      o.customer.save!
    end
    o.reload
    assert_equal 3, o.routes.size
    assert_equal 0, o.routes.find{ |ro| ro.ref == 'route_zero' }.stops.size
    assert_equal 5, o.routes.find{ |ro| ro.ref == 'route_one' }.stops.size
    assert_equal 1, o.routes.find{ |ro| ro.ref == 'route_three' }.stops.size
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
    # A valid Route and Vehicle Usage
    v = vehicle_usages(:vehicle_usage_one_one)
    r = v.routes.take

    # 1st computation, set Stop times
    r.compute
    stop_times = r.stops.map &:time
    route_end = r.end

    # Add Service Time
    v.vehicle_usage_set.update!(
      service_time_start: Time.utc(2000, 1, 1, 0, 0) + 10.minutes,
      service_time_end: Time.utc(2000, 1, 1, 0, 0) + 25.minutes
    )

    # 2nd computation
    r.compute
    stop_times2 = r.stops.map &:time
    route_end2 = r.end

    # Make sure time has been added to first stop and route end
    assert_equal stop_times[0] + 10.minutes, stop_times2[0]
    assert_equal route_end + 25.minutes, route_end2

    # Vehicle Usage overrides Service Time values
    v.update!(
      service_time_start: Time.utc(2000, 1, 1, 0, 0) + 30.minutes,
      service_time_end: Time.utc(2000, 1, 1, 0, 0) + 20.minutes
    )

    # 3rd computation
    r.compute
    stop_times3 = r.stops.map &:time
    route_end3 = r.end

    # Let's verify values for first stop and route end
    assert_equal stop_times[0] + 30.minutes, stop_times3[0]
    assert_equal route_end + 20.minutes, route_end3

    # Add Time Window to 1st Destination should set out of window flag
    assert !r.stops[0].out_of_window

    # Add a time window in service time start time (less than 30 minutes)
    r.stops[0].destination.update!(
      open: v.service_time_start + 5.minutes,
      close: v.service_time_start + 10.minutes
    )

    # Compute a last time, this stop should be out of time window
    r.compute
    assert r.stops[0].out_of_window
  end
end
