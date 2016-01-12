require 'test_helper'

class V01::OrdersTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @order = orders(:order_one)
  end

  def api(order_array_id, part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/order_arrays/#{order_array_id}/orders#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return order_array''s orders' do
    get api(@order.order_array.id)
    assert last_response.ok?, last_response.body
    assert_equal @order.order_array.orders.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s orders by ids' do
    get api(@order.order_array.id, nil, 'ids' => @order.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @order.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a order' do
    get api(@order.order_array.id, @order.id)
    assert last_response.ok?, last_response.body
    assert_equal @order.products.collect(&:id), JSON.parse(last_response.body)['product_ids']
  end

  test 'should update a order' do
    @order.product_ids = [products(:product_two).id]
    put api(@order.order_array.id, @order.id), {product_ids: @order.product_ids}
    assert last_response.ok?, last_response.body

    get api(@order.order_array.id, @order.id)
    assert last_response.ok?, last_response.body
    assert_equal @order.products.collect(&:id), JSON.parse(last_response.body)['product_ids']
  end
end
