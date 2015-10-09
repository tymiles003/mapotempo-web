require 'test_helper'

class VehiclesControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @vehicle = vehicles(:vehicle_one)
    sign_in users(:user_one)
    assert_valid response
  end

  test 'user can only view vehicles from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :index, vehicles(:vehicle_one)
    assert ability.can? :edit, vehicles(:vehicle_one)
    assert ability.can? :update, vehicles(:vehicle_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, vehicles(:vehicle_one)
    sign_in users(:user_three)
    get :edit, id: @vehicle
    assert_response :redirect
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:vehicles)
    assert_valid response
  end

  test 'should get edit' do
    get :edit, id: @vehicle
    assert_response :success
    assert_valid response
  end

  test 'should update vehicle' do
    patch :update, id: @vehicle, vehicle: { capacity: 123, color: @vehicle.color, consumption: @vehicle.consumption, emission: @vehicle.emission, name: @vehicle.name }
    assert_redirected_to vehicles_path
  end

  test 'should not update vehicle' do
    patch :update, id: @vehicle, vehicle: { name: '' }

    assert_template :edit
    vehicle = assigns(:vehicle)
    assert vehicle.errors.any?
    assert_valid response
  end
end
