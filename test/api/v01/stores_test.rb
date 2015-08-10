require 'test_helper'

class V01::StoresTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @store = stores(:store_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/stores#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=#{v}" }.join('&')
  end

  test 'should return customer''s stores' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @store.customer.stores.size, JSON.parse(last_response.body).size
  end

  test 'should return a store' do
    get api(@store.id)
    assert last_response.ok?, last_response.body
    assert_equal @store.name, JSON.parse(last_response.body)['name']
  end

  test 'should create a store' do
    assert_difference('Store.count', 1) do
      @store.name = 'new dest'
      post api(), @store.attributes
      assert last_response.created?, last_response.body
    end
  end

  test 'should destroy a store' do
    assert_difference('Store.count', -1) do
      delete api(@store.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple stores' do
    assert_difference('Store.count', -1) do
      delete api + "&ids[]=#{stores(:store_one).id}"
      assert last_response.ok?, last_response.body
    end
  end

  test 'should not destroy multiple all stores' do
    assert_difference('Store.count', 0) do
      delete api + "&ids[]=#{stores(:store_one).id}&ids[]=#{stores(:store_one_bis).id}"
      assert_not last_response.ok?
    end
  end

  test 'should geocode' do
    patch api('geocode'), format: :json, store: { city: @store.city, name: @store.name, postalcode: @store.postalcode, street: @store.street }
    assert last_response.ok?, last_response.body
  end

  test 'should geocode complete' do
    patch api('geocode_complete'), format: :json, id: @store.id, store: { city: 'Montpellier', street: 'Rue de la Chaînerais' }
    assert last_response.ok?, last_response.body
  end
end
