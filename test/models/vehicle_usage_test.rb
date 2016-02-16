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

#  test 'setting a time duration requires time start and stop' do
#    v = vehicle_usages(:vehicle_usage_one_one)
#    v.update! rest_start: nil, rest_stop: nil, rest_duration: nil
#    assert v.valid?
#    v.rest_duration = Time.utc(2000, 1, 1, 0, 0) + 15.minutes
#    assert !v.valid?
#    assert_equal [:rest_start, :rest_stop], v.errors.keys
#    v.rest_start = Time.utc(2000, 1, 1, 0, 0) + 10.hours
#    v.rest_stop = Time.utc(2000, 1, 1, 0, 0) + 11.hours
#    assert v.valid?
#  end

end
