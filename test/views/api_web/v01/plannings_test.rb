require 'test_helper'

class ApiWeb::V01::PlanningsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @planning = plannings(:planning_one)
  end

  test 'should return json for stop by index' do
    customers(:customer_one).update(job_optimizer_id: nil)
    get "/api-web/0.1/routes/#{@planning.routes.first.id}/stops/by_index/1.json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert json['stop_id']
    assert !json['manage_organize']
  end
end
