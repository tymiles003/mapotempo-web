require 'test_helper'

class V01::LayersTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @layer = layers(:layer_one)
    @current_customer = customers(:customer_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/layers#{part}.json?api_key=testkey1"
  end

  test 'should return customer''s layers' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @current_customer.profile.layers.size, JSON.parse(last_response.body).size
  end
end
