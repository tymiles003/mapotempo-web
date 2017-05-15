require 'test_helper'

class PlanningsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @planning = plannings(:planning_one)
  end

  test 'should return json for planning during optim' do
    get "/plannings/#{@planning.id}.json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_not_nil json['optimizer']
  end

  test 'should return json for planning' do
    customers(:customer_one).update(job_optimizer_id: nil)
    get "/plannings/#{@planning.id}.json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_equal @planning.routes.size, json['routes'].size
  end
end
