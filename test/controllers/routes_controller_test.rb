require 'test_helper'

class RoutesControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @route = routes(:route_one)
    sign_in users(:user_one)
  end

  test "should show route" do
    get :show, id: @route
    assert_response :success
  end

  test "should show route as csv" do
    get :show, id: @route, type: :csv
    assert_response :success
  end

  test "should show route as excel" do
    get :show, id: @route, format: :excel
    assert_response :success
  end

  test "should show route as gpx" do
    get :show, id: @route, format: :gpx
    assert_response :success
  end

  test "should update route" do
    patch :update, id: @route, route: { hidden: @route.hidden, locked: @route.locked, ref: "ref8" }
    assert_redirected_to route_path(assigns(:route))
  end
end
