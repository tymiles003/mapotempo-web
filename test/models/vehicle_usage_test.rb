require 'test_helper'

class VehicleUsageTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

#  test 'should not save' do
#    o = vehicle_usage_sets(:vehicle_usage_set_one).vehicle_usages.build()
#    assert_not o.save, 'Saved without required fields'
#  end

  test 'should save' do
    o = vehicle_usage_sets(:vehicle_usage_set_one).vehicle_usages.build(vehicle: vehicles(:vehicle_one))
    o.save!
  end

  test 'should update out_of_date for store' do
    s = stores(:store_one).dup
    s.save!
    o = vehicle_usages(:vehicle_usage_one_one)
    o.store_start = s
    assert_not o.routes[-1].out_of_date
    o.save!
    assert o.routes[-1].out_of_date
  end

  test 'should change store' do
    s = stores(:store_one).dup
    s.name = 's2'
    s.save!
    o = vehicle_usages(:vehicle_usage_one_one)
    o.store_start = s
    o.save!
    assert_equal s, o.store_start
    assert_not_equal s, o.store_stop
  end

  test 'changes on service time start should set route out of date' do
    v = vehicle_usages(:vehicle_usage_one_one)
    assert v.service_time_start.nil?
    r = v.routes.take
    assert !r.out_of_date
    v.update! service_time_start: Time.utc(2000, 1, 1, 0, 0) + 10.minutes
    assert r.reload.out_of_date
  end

  test 'changes on service time end should set route out of date' do
    v = vehicle_usages(:vehicle_usage_one_one)
    assert v.service_time_end.nil?
    r = v.routes.take
    assert !r.out_of_date
    v.update! service_time_end: Time.utc(2000, 1, 1, 0, 0) + 10.minutes
    assert r.reload.out_of_date
  end

 test 'setting a rest duration requires time start and stop' do
   v = vehicle_usages(:vehicle_usage_one_one)
   v.update! rest_start: nil, rest_stop: nil, rest_duration: nil
   assert v.valid?
   v.vehicle_usage_set.update! rest_start: nil, rest_stop: nil, rest_duration: nil
   v.rest_duration = Time.utc(2000, 1, 1, 0, 0) + 15.minutes
   assert !v.valid?
   assert_equal [:rest_start, :rest_stop], v.errors.keys
   v.rest_start = Time.utc(2000, 1, 1, 0, 0) + 10.hours
   v.rest_stop = Time.utc(2000, 1, 1, 0, 0) + 11.hours
   assert v.valid?
 end

  test 'disable vehicule usage' do
    # Stub Requests
    expected_response = File.read(Rails.root.join("test/web_mocks/osrm/route.json")).strip
    store = stores :store_one
    stub_request(:get, "http://localhost:5000/viaroute?alt=false&loc=#{store.lat},#{store.lng}&output=json").to_return(status: 200, body: expected_response)

    planning = plannings :planning_one
    out_of_route = planning.routes.detect{|route| !route.vehicle_usage }
    route = planning.routes.detect{|route| route.ref == 'route_one' }
    vehicle_usage = route.vehicle_usage

    # There are 3 Stops on this Route, + 1 Rest Stop
    assert_equal 3, route.stops.reload.select{|stop| stop.is_a?(StopVisit) }.count
    assert_equal 1, route.stops.reload.select{|stop| stop.is_a?(StopRest) }.count
    assert_equal 1, out_of_route.stops.reload.select{|stop| stop.is_a?(StopVisit) }.count

    # Scope includes Vehicle Usage
    assert VehicleUsage.active.find(route.vehicle_usage_id)

    # Deactivating Vehicle Usage
    assert vehicle_usage.active
    vehicle_usage.update! active: false
    assert !vehicle_usage.active

    # Scope does not include Vehicle Usage
    assert_raises ActiveRecord::RecordNotFound do
      VehicleUsage.active.find route.vehicle_usage_id
    end

    # All Stops are now out of route
    assert_raises ActiveRecord::RecordNotFound do
      route.reload
    end

    # Activating Vehicle Usage
    vehicle_usage.update! active: true
    assert vehicle_usage.active

    # Routes should be recreated
    route = planning.routes.reload.detect{|route| route.vehicle_usage_id == vehicle_usage.id }
    assert route.persisted?
    assert_equal 0, route.stops.reload.select{|stop| stop.is_a?(StopVisit) }.count
    assert_equal 1, route.stops.reload.select{|stop| stop.is_a?(StopRest) }.count
    assert_equal 4, out_of_route.stops.reload.select{|stop| stop.is_a?(StopVisit) }.count
  end
end
