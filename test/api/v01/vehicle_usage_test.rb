require 'test_helper'

class V01::VehicleUsagesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @vehicle_usage = vehicle_usages(:vehicle_usage_one_one)
  end

  def api(vehicle_usage_set_id, part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/vehicle_usage_sets/#{vehicle_usage_set_id}/vehicle_usages#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s vehicle_usages' do
    get api(@vehicle_usage.vehicle_usage_set.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle_usage.vehicle_usage_set.vehicle_usages.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s vehicle_usages by ids' do
    get api(@vehicle_usage.vehicle_usage_set.id, nil, 'ids' => @vehicle_usage.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @vehicle_usage.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a vehicle_usage' do
    get api(@vehicle_usage.vehicle_usage_set.id, @vehicle_usage.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle_usage.rest_duration.to_s.split(' ')[-2], JSON.parse(last_response.body)['rest_duration']
  end

  test 'should update a vehicle_usage' do
    @vehicle_usage.rest_duration = '23:00:00'
    put api(@vehicle_usage.vehicle_usage_set.id, @vehicle_usage.id), @vehicle_usage.attributes
    assert last_response.ok?, last_response.body

    get api(@vehicle_usage.vehicle_usage_set.id, @vehicle_usage.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle_usage.rest_duration.to_s.split(' ')[-2], JSON.parse(last_response.body)['rest_duration']
  end
end
