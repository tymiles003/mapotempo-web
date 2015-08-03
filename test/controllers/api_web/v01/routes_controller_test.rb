require 'test_helper'

class ApiWeb::V01::RoutesControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @route = routes(:route_one_one)
    sign_in users(:user_one)
  end

  test "should get routes" do
    get :index, planning_id: @route.planning_id
    assert_response :success
  end
end
