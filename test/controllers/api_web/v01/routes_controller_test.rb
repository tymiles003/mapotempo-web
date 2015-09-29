require 'test_helper'

class ApiWeb::V01::RoutesControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @route = routes(:route_one_one)
    sign_in users(:user_one)
  end

  test 'user can only view routes from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :index, routes(:route_one_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :index, routes(:route_one_one)
    sign_in users(:user_three)
    get :index, planning_id: @route.planning_id
    assert_response :redirect
    assert_nil assigns(:routes)
  end

  test 'should get routes' do
    get :index, planning_id: @route.planning_id
    assert_response :success
    assert_not_nil assigns(:routes)
    assert_valid response
  end
end
