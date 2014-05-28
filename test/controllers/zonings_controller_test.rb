require 'test_helper'

class ZoningsControllerTest < ActionController::TestCase
  setup do
    @zoning = zonings(:zoning_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:zonings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create zoning" do
    assert_difference('Zoning.count') do
      post :create, zoning: { name: @zoning.name, customer: @zoning.customer }
    end

    assert_redirected_to edit_zoning_path(assigns(:zoning))
  end

  test "should get edit" do
    get :edit, id: @zoning
    assert_response :success
  end

  test "should update zoning" do
    patch :update, id: @zoning, zoning: { name: @zoning.name, customer: @zoning.customer }
    assert_redirected_to edit_zoning_path(assigns(:zoning))
  end

  test "should destroy zoning" do
    assert_difference('Zoning.count', -1) do
      delete :destroy, id: @zoning
    end

    assert_redirected_to zonings_path
  end
end
