require 'test_helper'

class V01::ZoningsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @zoning = zonings(:zoning_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/zonings#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=#{v}" }.join('&')
  end

  test 'should return customer''s zonings' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @zoning.customer.zonings.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s zonings by ids' do
    get api(nil, 'ids' => @zoning.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @zoning.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a zoning' do
    get api(@zoning.id)
    assert last_response.ok?, last_response.body
    assert_equal @zoning.name, JSON.parse(last_response.body)['name']
  end

  test 'should create a zoning' do
    assert_difference('Zoning.count', 1) do
      @zoning.name = 'new name'
      post api(), @zoning.attributes
      assert last_response.created?, last_response.body
    end
  end

  test 'should update a zoning' do
    @zoning.name = 'new name'
    put api(@zoning.id), @zoning.attributes
    assert last_response.ok?, last_response.body

    get api(@zoning.id)
    assert last_response.ok?, last_response.body
    assert_equal @zoning.name, JSON.parse(last_response.body)['name']
  end

  test 'should destroy a zoning' do
    assert_difference('Zoning.count', -1) do
      delete api(@zoning.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple zonings' do
    assert_difference('Zoning.count', -2) do
      delete api + "&ids=#{zonings(:zoning_one).id},#{zonings(:zoning_two).id}"
      assert last_response.ok?, last_response.body
    end
  end

  test 'should generate zoning from planning' do
    patch api("#{@zoning.id}/from_planning/#{plannings(:planning_one).id}")
    assert last_response.ok?, last_response.body
    assert_equal @zoning.name, JSON.parse(last_response.body)['name']
  end

  test 'should generate zoning automatically' do
    patch api("#{@zoning.id}/automatic/#{plannings(:planning_one).id}")
    assert last_response.ok?, last_response.body
    assert_equal @zoning.name, JSON.parse(last_response.body)['name']
  end

  test 'should generate isochrone' do
    patch api("#{@zoning.id}/isochrone", size: 5)
    assert last_response.ok?, last_response.body
    assert_equal @zoning.name, JSON.parse(last_response.body)['name']
  end
end
