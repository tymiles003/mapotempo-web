require 'test_helper'

class VehicleUsageSetTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      yield
    end
  end

  test 'should not save' do
    o = customers(:customer_one).vehicle_usage_sets.build
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = customers(:customer_one).vehicle_usage_sets.build(name: '1')
    o.save!
  end

  test 'should update out_of_date for rest' do
    o = vehicle_usage_sets(:vehicle_usage_set_one)
    c = o.customer
    vu = o.vehicle_usages[0]
    vu.rest_duration = vu.rest_start = vu.rest_stop = nil
    vu.save!
    nb_vu_no_rest = o.vehicle_usages.select{ |vu| vu.rest_duration.nil? && vu.rest_start.nil? && vu.rest_stop.nil? }.size
    assert nb_vu_no_rest > 0
    nb = (c.vehicles.size - nb_vu_no_rest) * o.plannings.size
    assert nb > 0

    assert_difference('Stop.count', -nb) do
      o.vehicle_usages[0].routes[-1].compute
      o.vehicle_usages[0].routes[-1].out_of_date = false
      assert !o.rest_duration.nil?

      o.rest_duration = nil
      o.save!
      o.customer.save!
      assert o.vehicle_usages[0].routes[-1].out_of_date
    end
  end

  test 'should update out_of_date for open' do
    o = vehicle_usage_sets(:vehicle_usage_set_one)
    o.open = '2000-01-01 09:00:00'
    assert_not o.vehicle_usages[0].routes[-1].out_of_date
    o.save!
    assert o.vehicle_usages[0].routes[-1].out_of_date
  end

  test 'should delete in use' do
    assert_difference('VehicleUsageSet.count', -1) do
      customers(:customer_one).vehicle_usage_sets.delete(vehicle_usage_sets(:vehicle_usage_set_one))
    end
  end

  test 'should keep at least one' do
    o = customers(:customer_one)
    o.vehicle_usage_sets[0..-2].each(&:destroy)
    o.reload
    assert_equal 1, o.vehicle_usage_sets.size
    assert !o.vehicle_usage_sets[0].destroy
  end

  test 'changes on service time start should set route out of date' do
    v = vehicle_usage_sets(:vehicle_usage_set_one)
    assert v.service_time_start.nil?
    r = v.vehicle_usages.detect{|vehicle_usage| vehicle_usage.service_time_start.nil? }.routes.take
    assert !r.out_of_date
    v.update! service_time_start: Time.utc(2000, 1, 1, 0, 0) + 10.minutes
    assert r.reload.out_of_date
  end

  test 'changes on service time end should set route out of date' do
    v = vehicle_usage_sets(:vehicle_usage_set_one)
    assert v.service_time_end.nil?
    r = v.vehicle_usages.detect{|vehicle_usage| vehicle_usage.service_time_end.nil? }.routes.take
    assert !r.out_of_date
    v.update! service_time_end: Time.utc(2000, 1, 1, 0, 0) + 10.minutes
    assert r.reload.out_of_date
  end

#  test 'setting a time duration requires time start and stop' do
#    v = vehicle_usage_sets(:vehicle_usage_set_one)
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
