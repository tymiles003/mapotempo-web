require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      yield
    end
  end

  setup do
    @customer = customers(:customer_one)
  end

  test 'should not save' do
    o = Customer.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = resellers(:reseller_one).customers.build(name: 'test', max_vehicles: 5, default_country: 'France', router: routers(:router_one), profile: profiles(:profile_one))
    resellers(:reseller_one).save!
    o.max_vehicles = 5
    o.save!
  end

  test 'should stop job optimizer' do
    assert_difference('Delayed::Backend::ActiveRecord::Job.count', -1) do
      @customer.job_optimizer.destroy
    end
  end

  test 'should destination add' do
    c = customers(:customer_one)
    assert_difference('Destination.count') do
      d = c.destinations.build(name: 'new', city: 'Parlà')
      d.visits.build(tags: [tags(:tag_one)])
      c.save!
    end
  end

  test 'should update_out_of_date' do
    o = customers(:customer_one)
    o.take_over = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    o.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert_not r.out_of_date
    }}
    o.save!
    o.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert r.out_of_date
    }}
  end

  test 'should update_max_vehicles up' do
    o = customers(:customer_one)
    assert_difference('Vehicle.count', 1) do
      assert_difference('VehicleUsage.count', o.vehicle_usage_sets.length) do
        assert_difference('Route.count', o.plannings.length) do
          o.max_vehicles += 1
          o.save!
        end
      end
    end
  end

  test 'should update_max_vehicles down' do
    o = customers(:customer_one)
    assert_difference('Vehicle.count', -1) do
      assert_difference('VehicleUsage.count', -o.vehicle_usage_sets.length) do
        assert_difference('Route.count', -o.plannings.length) do
          o.max_vehicles -= 1
          o.save!
        end
      end
    end
  end

  test 'should create and destroy' do
    customer = resellers(:reseller_one).customers.build(name: 'plop', max_vehicles: 5, default_country: 'France', router: routers(:router_one), profile: profiles(:profile_one))
    resellers(:reseller_one).save!
    assert customer.stores.size > 0
    assert customer.vehicles.size > 0
    assert customer.vehicle_usage_sets.size > 0
    customer.destroy
  end
end
