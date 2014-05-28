require 'test_helper'

class VehiclesControllerTest < ActionController::TestCase
  setup do
    @vehicle = vehicles(:vehicle_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:vehicles)
  end

  test "should get edit" do
    get :edit, id: @vehicle
    assert_response :success
  end

  test "should update vehicle" do
    patch :update, id: @vehicle, vehicle: { capacity: @vehicle.capacity, close: @vehicle.close, color: @vehicle.color, consumption: @vehicle.consumption, emission: @vehicle.emission, name: @vehicle.name, open: @vehicle.open, customer: @vehicle.customer }
    assert_redirected_to vehicles_path
  end
end
