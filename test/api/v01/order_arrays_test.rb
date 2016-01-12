require 'test_helper'

class V01::OrderArraysTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @order_array = order_arrays(:order_array_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/order_arrays#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s order_arrays' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @order_array.customer.order_arrays.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s order_arrays by ids' do
    get api(nil, 'ids' => @order_array.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @order_array.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a order_array' do
    get api(@order_array.id)
    assert last_response.ok?, last_response.body
    assert_equal @order_array.name, JSON.parse(last_response.body)['name']
  end

  test 'should create a order_array' do
    assert_difference('OrderArray.count', 1) do
      post api(), {name: 'new name', length: @order_array.length, base_date: Date.new}
      assert last_response.created?, last_response.body
    end
  end

  test 'should update a order_array' do
    put api(@order_array.id), {name: 'new name'}
    assert last_response.ok?, last_response.body

    get api(@order_array.id)
    assert last_response.ok?, last_response.body
    assert_equal 'new name', JSON.parse(last_response.body)['name']
  end

  test 'should destroy a order_array' do
    assert_difference('OrderArray.count', -1) do
      delete api(@order_array.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple order_arrays' do
    assert_difference('OrderArray.count', -2) do
      delete api + "&ids=#{order_arrays(:order_array_one).id},#{order_arrays(:order_array_two).id}"
      assert last_response.ok?, last_response.body
    end
  end

  test 'should clone the order_array' do
    assert_difference('OrderArray.count', 1) do
      patch api("#{@order_array.id}/duplicate")
      assert last_response.ok?, last_response.body
    end
  end

  test 'should do orders mass assignment' do
    @order = orders(:order_one)
    @order.product_ids = [products(:product_two).id]
    put api(@order.order_array.id), {@order.id => @order.attributes}
    assert last_response.ok?, last_response.body

    @order.reload
    assert_equal [products(:product_two).id], @order.product_ids
  end
end
