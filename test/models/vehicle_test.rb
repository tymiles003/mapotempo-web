require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = customers(:customer_one).vehicles.build
    assert_not o.save, "Saved without required fields"
  end

  test "should save" do
    o = customers(:customer_one).vehicles.build(name: "1")
    o.save!
  end

  test "should update out_of_date for capacity" do
    o = vehicles(:vehicle_one)
    o.capacity = 123
    assert_not o.routes[-1].out_of_date
    o.save!
    assert o.routes[-1].out_of_date
  end

  test "should update out_of_date for store" do
    s = stores(:store_one).dup
    s.save!
    o = vehicles(:vehicle_one)
    o.store_start = s
    assert_not o.routes[-1].out_of_date
    o.save!
    assert o.routes[-1].out_of_date
  end

  test "should change store" do
    s = stores(:store_one).dup
    s.name = "s2"
    s.save!
    o = vehicles(:vehicle_one)
    o.store_start = s
    o.save!
    assert_equal s, o.store_start
    assert_not_equal s, o.store_stop
  end
end
