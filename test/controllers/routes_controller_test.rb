require 'test_helper'

class RoutesControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @route = routes(:route_one)
    sign_in users(:user_one)
  end

  test "should show route" do
    get :show, id: @route
    assert_response :success
  end

  test "should update route" do
    patch :update, id: @route, route: { distance: @route.distance, emission: @route.emission }
    assert_redirected_to route_path(assigns(:route))
  end
end
