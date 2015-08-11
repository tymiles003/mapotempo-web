require 'test_helper'

class ApiWeb::StoresControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @store = stores(:store_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:stores)
  end

  test "should get edit position" do
    get :edit_position, id: @store
    assert_response :success
  end

  test "should update position" do
    patch :update_position, id: @store, store: { lat: 6, lng: 6 }
    assert_redirected_to api_web_edit_position_store_path(assigns(:store))
  end
end
