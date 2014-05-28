require 'test_helper'

class PlanningsControllerTest < ActionController::TestCase
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

  test "should get edit" do
    get :edit, id: @planning
    assert_response :success
  end

  test "should update planning" do
    patch :update, id: @planning, planning: { name: @planning.name, customer: @planning.customer, zoning: @planning.zoning }
    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should destroy planning" do
    assert_difference('Planning.count', -1) do
      delete :destroy, id: @planning
    end

    assert_redirected_to plannings_path
  end
end
