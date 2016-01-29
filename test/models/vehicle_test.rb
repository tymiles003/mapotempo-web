require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      yield
    end
  end

  test 'should not save' do
    o = customers(:customer_one).vehicles.build
    assert_not o.save, 'Saved without required fields'
  end

  test 'should not save, speed_multiplicator' do
    o = customers(:customer_one).vehicles.build(name: 'plop', speed_multiplicator: 2)
    assert_not o.save
  end

  test 'should save' do
    o = customers(:customer_one).vehicles.build(name: '1')
    o.save!
  end

  test 'should update out_of_date for capacity' do
    o = vehicles(:vehicle_one)
    o.capacity = 123
    assert_not o.vehicle_usages[0].routes[-1].out_of_date
    o.save!
    assert o.vehicle_usages[0].routes[-1].out_of_date
  end

  test 'should validate email' do
    v = vehicles(:vehicle_one)
    assert v.contact_email.nil?
    assert v.valid?
    assert v.update! contact_email: ""
    assert v.valid?
    assert v.update! contact_email: "test@example.com"
    assert v.valid?
  end
end
