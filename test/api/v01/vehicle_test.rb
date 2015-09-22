require 'test_helper'

class V01::VehiclesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @vehicle = vehicles(:vehicle_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/vehicles#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=#{v}" }.join('&')
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
end
