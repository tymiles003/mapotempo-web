require 'test_helper'

class V01::OrderArraysTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  test 'Order Array Empty Row' do
    order_array = order_arrays :order_array_one
    assert order_array.orders[0].reload.products.exists?
    order_params = order_array.order_ids.each_with_object({}){|order_id, hash| hash[order_id.to_s] = { 'product_ids' => [0] }}
    patch "/api/0.1/order_arrays/#{order_array.id}.json", { orders: order_params.to_json, api_key: 'testkey1' }
    assert last_response.ok?
    assert order_array.orders[0].reload.products.none?
  end
end
