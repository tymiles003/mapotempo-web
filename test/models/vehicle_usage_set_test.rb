require 'test_helper'

class VehicleUsageSetTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
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
    assert_difference('Stop.count', -1) do
      o = vehicle_usage_sets(:vehicle_usage_set_one)
      o.rest_duration = nil
      o.save!
      assert_not o.vehicle_usages[0].routes[-1].out_of_date
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
    assert_raises RuntimeError do
      o.vehicle_usage_sets.each(&:destroy)
      o.save!
    end
  end
end
