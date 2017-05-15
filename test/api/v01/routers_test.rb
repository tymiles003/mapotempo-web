require 'test_helper'

class V01::RoutersTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @router = routers(:router_one)
    @current_customer = customers(:customer_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/routers#{part}.json?api_key=testkey1"
  end

  test "should return customer's routers" do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @current_customer.profile.routers.size, JSON.parse(last_response.body).size
  end
end
