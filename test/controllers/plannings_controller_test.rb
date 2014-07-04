require 'test_helper'

class PlanningsControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @planning = plannings(:planning_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:plannings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create planning" do
    assert_difference('Planning.count') do
      post :create, planning: { name: @planning.name, customer: @planning.customer, zoning: @planning.zoning }
    end

    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should not create planning" do
    assert_difference('Planning.count', 0) do
      post :create, planning: { name: "", customer: @planning.customer }
    end

    assert_template :new
    planning = assigns(:planning)
    assert planning.errors.any?
  end

  test "should show planning" do
    get :show, id: @planning
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @planning
    assert_response :success
  end

  test "should update planning" do
    patch :update, id: @planning, planning: { name: @planning.name, customer: @planning.customer, zoning: @planning.zoning }
    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should not update planning" do
    patch :update, id: @planning, planning: { name: "", customer: @planning.customer }

    assert_template :edit
    planning = assigns(:planning)
    assert planning.errors.any?
  end

  test "should destroy planning" do
    assert_difference('Planning.count', -1) do
      delete :destroy, id: @planning
    end

    assert_redirected_to plannings_path
  end

  test "should move" do
    patch :move, planning_id: @planning, format: :json, planning: { name: @planning.name, customer: @planning.customer, zoning: @planning.zoning }
    assert_response :success
  end

  test "should refresh" do
    get :refresh, planning_id: @planning, format: :json
    assert_response :success
  end

  test "should switch" do
    patch :switch, planning_id: @planning, format: :json, route_id: routes(:route_one).id, vehicle_id: vehicles(:vehicle_one).id
    assert_response :success, id: @planning
  end

  test "should update stop" do
    patch :update_stop, planning_id: @planning, format: :json, route_id: routes(:route_one).id, destination_id: destinations(:destination_one).id, stop: { active: false }
    assert_response :success
  end

  test "should optimize route" do
    get :optimize_route, planning_id: @planning, format: :json, route_id: routes(:route_one).id
    assert_response :success
  end

  test "should duplicate" do
    assert_difference('Planning.count') do
      patch :duplicate, planning_id: @planning
    end

    assert_redirected_to edit_planning_path(assigns(:planning))
  end
end
