require 'test_helper'

class V01::CustomerTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @customer = customers(:customer_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/customers#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  def api_admin(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/customers#{part}.json?api_key=adminkey"
  end

  test 'should list customers' do
    get api_admin
    assert last_response.ok?, last_response.body
    assert_equal resellers(:reseller_one).customers.size, JSON.parse(last_response.body).size
  end

  test 'should not list customers' do
    get api
    assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
  end

  test 'should return a customer' do
    get api('ref:' + @customer.ref)
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_equal @customer.name, json['name']
    assert_equal @customer.ref, json['ref']

    get api_admin(@customer.id)
    assert last_response.ok?, last_response.body
  end

  test 'should not return a customer' do
    get api(customers(:customer_two).id)
    assert_equal 404, last_response.status, 'Bad response: ' + last_response.body

    get api_admin(customers(:customer_two).id)
    assert_equal 404, last_response.status, 'Bad response: ' + last_response.body
  end

  test 'should update a customer' do
    put api(@customer.id), { tomtom_user: 'tomtom_user_abcd', ref: 'ref-abcd' }
    assert last_response.ok?, last_response.body
    get api(@customer.id)
    assert last_response.ok?, last_response.body
    assert_equal 'tomtom_user_abcd', JSON.parse(last_response.body)['tomtom_user']
    assert 'ref-abcd' != JSON.parse(last_response.body)['ref']
  end

  test 'should update a customer in admin' do
    put api_admin(@customer.id), { tomtom_user: 'tomtom_user_abcd', ref: 'ref-abcd' }
    assert last_response.ok?, last_response.body

    get api(@customer.id)
    assert last_response.ok?, last_response.body
    assert_equal 'tomtom_user_abcd', JSON.parse(last_response.body)['tomtom_user']
    assert_equal 'ref-abcd', JSON.parse(last_response.body)['ref']
  end

  test 'should not update a customer' do
    customer = customers(:customer_two)
    customer.ref = 'new ref'

    put api_admin(customer.id), customer.attributes
    assert_equal 404, last_response.status, 'Bad response: ' + last_response.body

    put api(customer.id), customer.attributes
    assert_equal 404, last_response.status, 'Bad response: ' + last_response.body
  end

  test 'should create a customer' do
    begin
      # test with 2 different configs
      manage_vehicles_only_admin = Mapotempo::Application.config.manage_vehicles_only_admin
      [true, false].each { |v|
        Mapotempo::Application.config.manage_vehicles_only_admin = v

        assert_difference('Customer.count', 1) do
          assert_difference('Store.count', 1) do
            assert_difference('VehicleUsageSet.count', 1) do
              assert_difference('Vehicle.count', 5) do
                post api_admin, {name: 'new cust', max_vehicles: 5, default_country: 'France', router_id: @customer.router_id, profile_id: @customer.profile_id}
                assert last_response.created?, last_response.body
                assert_equal 5, JSON.parse(last_response.body)['max_vehicles']
              end
            end
          end
        end
      }
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = manage_vehicles_only_admin
    end
  end

  test 'should not create a customer' do
    assert_no_difference 'Customer.count' do
      post api_admin, { name: 'new cust', ref: @customer.ref, default_country: 'France', max_vehicles: 2, router_id: @customer.router_id, profile_id: @customer.profile_id }
      assert_equal 400, last_response.status, 'Bad response: ' + last_response.body

      post api, { name: 'new cust', default_country: 'France', max_vehicles: 2, router_id: @customer.router_id, profile_id: @customer.profile_id }
      assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
    end
  end

  test 'should destroy a customer' do
    assert_difference('Customer.count', -1) do
      delete api_admin('ref:' + @customer.ref)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should not destroy a customer' do
    assert_no_difference('Customer.count') do
      delete api_admin('ref:' + customers(:customer_two).ref)
      assert_equal 404, last_response.status, 'Bad response: ' + last_response.body

      delete api(@customer.id)
      assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
    end
  end

  test 'should get job' do
    get api("#{@customer.id}/job/#{@customer.job_optimizer_id}")
    assert last_response.ok?, last_response.body
  end

  test 'should delete job' do
    assert_difference('Delayed::Backend::ActiveRecord::Job.count', -1) do
      delete api("#{@customer.id}/job/#{@customer.job_destination_geocoding_id}")
      assert last_response.ok?, last_response.body
    end
  end

  test 'should duplicate customer' do
    assert_difference('Customer.count', +1) do
      put api_admin(@customer.id.to_s + '/duplicate')
      assert last_response.ok?
    end
  end

  test 'should not duplicate customer' do
    assert_no_difference('Customer.count') do
      put api_admin(customers(:customer_two).id.to_s + '/duplicate')
      assert_equal 404, last_response.status, 'Bad response: ' + last_response.body

      put api(@customer.id.to_s + '/duplicate')
      assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
    end
  end

end
