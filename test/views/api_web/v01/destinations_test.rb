require 'test_helper'

class ApiWeb::V01::DestinationsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @customer = customers(:customer_one)
    @customer.update(enable_orders: false)
  end

  test 'Api-web: should return json for destinations' do
    [:get, :post].each do |method|
      send method, "/api-web/0.1/destinations.json?api_key=testkey1"
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal @customer.destinations.size, json['destinations'].size
    end
  end

  test 'Api-web: should return json for some destinations' do
    [:get, :post].each do |method|
      send method, "/api-web/0.1/destinations.json?api_key=testkey1", {ids: destinations(:destination_one).id.to_s}
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal 1, json['destinations'].size
    end
  end
end
