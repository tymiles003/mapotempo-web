require 'test_helper'

class V01::VehiclesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      yield
    end
  end

  setup do
    @vehicle = vehicles(:vehicle_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/vehicles#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  def api_admin(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/vehicles#{part}.json?api_key=adminkey&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s vehicles' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @vehicle.customer.vehicles.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s vehicles by ids' do
    get api(nil, 'ids' => @vehicle.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @vehicle.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a vehicle' do
    get api(@vehicle.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle.name, JSON.parse(last_response.body)['name']
  end

  test 'should update a vehicle' do
    @vehicle.name = 'new name'
    put api(@vehicle.id), @vehicle.attributes
    assert last_response.ok?, last_response.body

    get api(@vehicle.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle.name, JSON.parse(last_response.body)['name']
  end

  test 'should create a vehicle' do
    begin
      manage_vehicles_only_admin = Mapotempo::Application.config.manage_vehicles_only_admin
      Mapotempo::Application.config.manage_vehicles_only_admin = false

      customer = customers(:customer_one)

      # test creation and callbacks
      assert_difference('Vehicle.count', 1) do
        assert_difference('VehicleUsage.count', customer.vehicle_usage_sets.length) do
          assert_difference('Route.count', customer.plannings.length) do
            post api, { ref: 'new', name: 'Vh1', open: '10:00:00', store_start_id: stores(:store_zero).id, store_stop_id: stores(:store_zero).id, customer_id: customers(:customer_one).id, color: '#bebeef' }
            assert last_response.created?, last_response.body
            assert_equal '#bebeef', JSON.parse(last_response.body)['color']
          end
        end
      end
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = manage_vehicles_only_admin
    end
  end

  test 'should create and destroy a vehicle' do
    begin
      customer = customers(:customer_one)
      # test with 2 different configs
      manage_vehicles_only_admin = Mapotempo::Application.config.manage_vehicles_only_admin
      [true, false].each { |v|
        Mapotempo::Application.config.manage_vehicles_only_admin = v

        new_name = 'new vehicle'
        # test creation and callbacks
        assert_difference('Vehicle.count', 1) do
          assert_difference('VehicleUsage.count', customer.vehicle_usage_sets.length) do
            assert_difference('Route.count', customer.plannings.length) do
              post v ? api_admin : api, { ref: 'new', name: new_name, open: '10:00:00', store_start_id: stores(:store_zero).id, store_stop_id: stores(:store_zero).id, customer_id: customers(:customer_one).id }
              assert last_response.created?, last_response.body
            end
          end
        end

        # test assign attributes
        get api(nil, {ids: 'ref:new'})
        assert last_response.ok?, last_response.body
        assert_equal new_name, JSON.parse(last_response.body)[0]['name']
        id = JSON.parse(last_response.body)[0]['id']
        customer.vehicle_usage_sets.each { |s|
          get "/api/0.1/vehicle_usage_sets/" + s.id.to_s + "/vehicle_usages.json?api_key=testkey1"
          hash = JSON.parse(last_response.body)
          u = hash.find{ |u| u['vehicle']['id'] == id }
          assert_equal '10:00:00', u['open']
          assert_equal stores(:store_zero).id, u['store_start_id']
        }

        # test deletion
        assert_difference('Vehicle.count', -1) do
          assert_difference('VehicleUsage.count', -customer.vehicle_usage_sets.length) do
            assert_difference('Route.count', -customer.plannings.length) do
              delete (v ? api_admin('ref:new') : api('ref:new')) + "&customer_id=#{@vehicle.customer.id}"
              assert last_response.ok?, last_response.body
            end
          end
        end
      }
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = manage_vehicles_only_admin
    end
  end

  test 'should create and destroy multiple vehicles' do
    begin
      customer = customers(:customer_one)
      # test with 2 different configs
      manage_vehicles_only_admin = Mapotempo::Application.config.manage_vehicles_only_admin
      [true, false].each { |v|
        Mapotempo::Application.config.manage_vehicles_only_admin = v

        new_name = 'new vehicle 1'
        post v ? api_admin : api, { ref: 'new1', name: new_name, store_start_id: stores(:store_zero).id, store_stop_id: stores(:store_zero).id, customer_id: customers(:customer_one).id }
        assert last_response.created?, last_response.body
        new_name = 'new vehicle 2'
        post v ? api_admin : api, { ref: 'new2', name: new_name, store_start_id: stores(:store_zero).id, store_stop_id: stores(:store_zero).id, customer_id: customers(:customer_one).id }
        assert last_response.created?, last_response.body

        assert_difference('Vehicle.count', -2) do
          assert_difference('VehicleUsage.count', -2 * customer.vehicle_usage_sets.length) do
            assert_difference('Route.count', -2 * customer.plannings.length) do
              delete (v ? api_admin : api) + "&customer_id=#{@vehicle.customer.id}&ids=ref:new1,ref:new2"
              assert last_response.ok?, last_response.body
            end
          end
        end
      }
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = manage_vehicles_only_admin
    end
  end

  test 'should not destroy last vehicle' do
    begin
      manage_vehicles_only_admin = Mapotempo::Application.config.manage_vehicles_only_admin
      [true, false].each { |v|
        Mapotempo::Application.config.manage_vehicles_only_admin = v
        @vehicle.customer.vehicles[0..-2].each{ |vehicle|
          delete (v ? api_admin("/#{vehicle.id}") : api) + "&customer_id=#{@vehicle.customer.id}"
        }
        assert_no_difference('Vehicle.count') do
          vehicle = @vehicle.customer.vehicles[-1]
            delete (v ? api_admin("/#{vehicle.id}") : api) + "&customer_id=#{@vehicle.customer.id}"
            assert last_response.server_error?, last_response.body
        end
      }
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = manage_vehicles_only_admin
    end
  end

  test 'should not destroy all vehicles' do
    begin
      manage_vehicles_only_admin = Mapotempo::Application.config.manage_vehicles_only_admin
      [true, false].each { |v|
        Mapotempo::Application.config.manage_vehicles_only_admin = v
        assert_no_difference('Vehicle.count') do
          delete (v ? api_admin() : api) + "&customer_id=#{@vehicle.customer.id}&ids=#{vehicles(:vehicle_one).id},#{vehicles(:vehicle_three).id}"
          assert last_response.server_error?, last_response.body
        end
      }
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = manage_vehicles_only_admin
    end
  end
end
