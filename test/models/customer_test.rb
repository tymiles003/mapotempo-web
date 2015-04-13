require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @customer = customers(:customer_one)
  end

  test "should not save" do
    o = Customer.new
    assert_not o.save, "Saved without required fields"
  end

  test "should save" do
    o = Customer.new(name: 'test', router: routers(:router_one), profile: profiles(:profile_one))
    o.save!
    o.max_vehicles = 5
    o.save!
  end

  test "should stop job optimizer" do
    assert_difference('Delayed::Backend::ActiveRecord::Job.count', -1) do
      @customer.job_optimizer.destroy
    end
  end

  test "should destination add" do
    o = customers(:customer_one)
    assert_difference('Destination.count') do
      o.destinations.build(name: 'new', city: 'Parlà', tags: [tags(:tag_one)]).save!
      o.save!
    end
  end

  test "should update_out_of_date" do
    o = customers(:customer_one)
    o.take_over = Time.new(2000, 01, 01, 00, 10, 00, "+00:00")
    o.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle }.each{ |r|
        assert_not r.out_of_date
    }}
    o.save!
    o.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle }.each{ |r|
        assert r.out_of_date
    }}
  end

  test "should update_max_vehicles up" do
    o = customers(:customer_one)
    assert_difference('Vehicle.count') do
      o.max_vehicles += 1
      o.save!
    end
  end

  test "should update_max_vehicles down" do
    o = customers(:customer_one)
    assert_difference('Vehicle.count', -1) do
      o.max_vehicles -= 1
      o.save!
    end
  end

  test "should create and destroy" do
    customer = Customer.new(name: 'plop', router: routers(:router_one), profile: profiles(:profile_one))
    customer.save!
    customer.destroy
  end
end
