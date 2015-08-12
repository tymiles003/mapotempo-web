require 'test_helper'

class ApiWeb::V01::DestinationsControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @destination = destinations(:destination_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:destinations)
  end

  test "should get edit position" do
    get :edit_position, id: @destination
    assert_response :success
  end

  test "should update position" do
    patch :update_position, id: @destination, destination: { lat: 6, lng: 6 }
    assert_redirected_to api_web_v01_edit_position_destination_path(assigns(:destination))
  end
end
