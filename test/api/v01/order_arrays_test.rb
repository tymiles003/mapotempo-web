require 'test_helper'

class V01::OrderArraysTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  def api path, params = {}
    Addressable::Template.new("/api/0.1/#{path}{?query*}").expand(query: params).to_s
  end

  test 'Order Array Empty Row' do
    order_array = order_arrays :order_array_one
    assert order_array.orders[0].reload.products.any?
    params = order_array.order_ids.each_with_object({}){|order_id, hash| hash[order_id] = { product_ids: [] }}
    params = params.to_json.to_s # JSON.stringify equivalent
    patch api("order_arrays/#{order_array.id}.json", { orders: params, api_key: 'testkey1' })
    assert last_response.ok?
    assert order_array.orders[0].reload.products.none?
  end

end
