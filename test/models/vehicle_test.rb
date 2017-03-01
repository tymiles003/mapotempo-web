require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |_url, _mode, _dimension, segments, _options| segments.collect{ |_i| [1, 1, 'trace'] } } ) do
      yield
    end
  end

  test 'should not save' do
    vehicle = customers(:customer_one).vehicles.build
    assert_not vehicle.save, 'Saved without required fields'
  end

  test 'should not save speed_multiplicator' do
    vehicle = customers(:customer_one).vehicles.build(name: 'plop', speed_multiplicator: 2)
    assert_not vehicle.save
  end

  test 'should save' do
    vehicle = customers(:customer_one).vehicles.build(name: '1')
    vehicle.save!
  end

  test 'should set hash router options' do
    vehicle = customers(:customer_one).vehicles.build(name: '2')
    vehicle.router_options = {
        time: true,
        distance: true,
        isochrone: true,
        isodistance: true,
        avoid_zones: true,
        motorway: true,
        toll: true,
        trailers: 2,
        weight: 10,
        weight_per_axle: 5,
        height: 5,
        width: 6,
        length: 30,
        hazardous_goods: 'gas'
    }

    vehicle.save!

    assert vehicle.time, true
    assert vehicle.time?, true

    assert vehicle.distance, true
    assert vehicle.distance?, true

    assert vehicle.isochrone, true
    assert vehicle.isochrone?, true

    assert vehicle.isodistance, true
    assert vehicle.isodistance?, true

    assert vehicle.avoid_zones, true
    assert vehicle.avoid_zones?, true

    assert vehicle.motorway, true
    assert vehicle.motorway?, true

    assert vehicle.toll, true
    assert vehicle.toll?, true

    assert vehicle.trailers, 2
    assert vehicle.weight, 10
    assert vehicle.weight_per_axle, 5
    assert vehicle.height, 5
    assert vehicle.width, 6
    assert vehicle.length, 30
    assert vehicle.hazardous_goods, 'gas'
  end

  test 'should use default router options' do
    customer = customers(:customer_two)
    customer.router_options = {
        motorway: true,
        trailers: 2,
        weight: 10
    }

    vehicle = customer.vehicles.build(name: '3')
    vehicle.router_options = {
        motorway: false,
        weight_per_axle: 3,
        length: 30,
        hazardous_goods: 'gas'
    }
    vehicle.save!

    assert vehicle.default_router_options['motorway'], 'false'
    assert vehicle.default_router_options['trailers'], '2'
    assert vehicle.default_router_options['weight'], '10'
    assert vehicle.default_router_options['weight_per_axle'], '3'
    assert vehicle.default_router_options['length'], '30'
    assert vehicle.default_router_options['hazardous_goods'], 'gas'
  end

  test 'should update out_of_date for capacity' do
    vehicle = vehicles(:vehicle_one)
    vehicle.capacities = {customers(:customer_one).deliverable_units[0].id => '12,3'}
    assert_not vehicle.vehicle_usages[0].routes[-1].out_of_date
    vehicle.save!
    assert vehicle.vehicle_usages[0].routes[-1].out_of_date
    assert 12.3, Vehicle.where(name: :vehicle_one).first.capacities[customers(:customer_one).deliverable_units[0].id]
  end

  test 'should validate email' do
    vehicle = vehicles(:vehicle_one)
    assert vehicle.valid?
    assert vehicle.update! contact_email: ''
    assert vehicle.contact_email.nil?
    assert vehicle.valid?
  end
end
