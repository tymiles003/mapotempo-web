require 'test_helper'

class VehicleUsagesControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @vehicle_usage = vehicle_usages(:vehicle_usage_one_one)
    sign_in users(:user_one)
    assert_valid response
  end

  test 'user can only view vehicle_usages from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :edit, vehicle_usages(:vehicle_usage_one_one)
    assert ability.can? :update, vehicle_usages(:vehicle_usage_one_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, vehicle_usages(:vehicle_usage_one_one)
    sign_in users(:user_three)
    get :edit, id: @vehicle_usage
    assert_response :redirect
  end

  test 'should get edit' do
    get :edit, id: @vehicle_usage
    assert_response :success
    assert_valid response
  end

  test 'should update vehicle_usage' do
    patch :update, id: @vehicle_usage, vehicle_usage: { vehicle: {capacity: 123, color: @vehicle_usage.vehicle.color, consumption: @vehicle_usage.vehicle.consumption, emission: @vehicle_usage.vehicle.emission, name: @vehicle_usage.vehicle.name},  open: @vehicle_usage.open}
    assert_redirected_to edit_vehicle_usage_path(@vehicle_usage)
  end

  test 'should not update vehicle_usage' do
    patch :update, id: @vehicle_usage, vehicle_usage: { vehicle: {name: ''} }

    assert_template :edit
    vehicle_usage = assigns(:vehicle_usage)
    assert vehicle_usage.errors.any?
    assert_valid response
  end

  test 'disable vehicule usage' do
    patch :toggle, id: @vehicle_usage.id
    assert !@vehicle_usage.reload.active
    assert_redirected_to vehicle_usage_sets_path
  end

end
