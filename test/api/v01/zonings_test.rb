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
    "/api/0.1/zonings#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
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

  test 'should generate isochrone and isodistance' do
    store_one = stores(:store_one)
    [:isochrone, :isodistance].each{ |isowhat|
      uri_template = Addressable::Template.new('localhost:1723/0.1/' + isowhat.to_s + '?lat=' + store_one.lat.to_s + '&lng=' + store_one.lng.to_s + '&time={time}')
      stub_table = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
      patch api("#{@zoning.id}/" + isowhat.to_s, vehicle_usage_set_id: vehicle_usage_sets(:vehicle_usage_set_one).id, size: 5)
      assert last_response.ok?, last_response.body
      assert_equal 1, JSON.parse(last_response.body)['zones'].length
      assert_not_nil JSON.parse(last_response.body)['zones'][0]['polygon']
    }
  end

  test 'should generate isochrone and isodistance for one vehicle' do
    store_one = stores(:store_one)
    [:isochrone, :isodistance].each{ |isowhat|
      uri_template = Addressable::Template.new('localhost:1723/0.1/' + isowhat.to_s + '?lat=' + store_one.lat.to_s + '&lng=' + store_one.lng.to_s + '&time={time}')
      stub_table = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
      patch api("#{@zoning.id}/vehicle_usage/" + vehicle_usages(:vehicle_usage_one_one).id.to_s + "/" + isowhat.to_s, size: 5)
      assert last_response.ok?, last_response.body
      assert_not_nil JSON.parse(last_response.body)['polygon']
    }
  end

  test 'should generate an isochrone zone' do
    store_one = stores(:store_one)
    [:isochrone, :isodistance].each { |iso|
      type = (iso == :isochrone) ? '&time=60' : '&size=10'
      uri_template = Addressable::Template.new('localhost:1723/0.1/' + iso.to_s + '?lat=' + store_one.lat.to_s + '&lng=' + store_one.lng.to_s + type)
      stub_table = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
      patch api(iso.to_s, {lat: store_one.lat.to_s, lng: store_one.lng.to_s, size: 10})
      assert last_response.ok?, last_response.body
    }
  end
end
