require 'test_helper'

class DestinationsControllerTest < ActionController::TestCase
  setup do
    @destination = destinations(:destination_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:destinations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create destination" do
    assert_difference('Destination.count') do
      post :create, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, customer: @destination.customer, detail: @destination.detail, comment: @destination.comment }
    end

    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test "should get edit" do
    get :edit, id: @destination
    assert_response :success
  end

  test "should update destination" do
    patch :update, id: @destination, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, customer: @destination.customer, detail: @destination.detail, comment: @destination.comment }
    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test "should destroy destination" do
    assert_difference('Destination.count', -1) do
      delete :destroy, id: @destination
    end

    assert_redirected_to destinations_path
  end
end
