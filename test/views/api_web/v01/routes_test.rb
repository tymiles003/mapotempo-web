require 'test_helper'

class ApiWeb::V01::PlanningsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    customers(:customer_one).update(enable_orders: false)
    @planning = plannings(:planning_one)
  end

  test 'Api-web: should return json for planning' do
    get "/api-web/0.1/plannings/#{@planning.id}/routes.json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_equal @planning.routes.size, json['routes'].size
  end

  test 'Api-web: should return json for only one route' do
    route = @planning.routes[0]
    get "/api-web/0.1/plannings/#{@planning.id}/routes.json?ids=#{route.id}&api_key=testkey1"
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_equal 1, json['routes'].size
  end
end
