require 'test_helper'

class VehicleUsageSetsControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    sign_in users(:user_one)
    assert_valid response
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      yield
    end
  end

  test 'user can only view vehicle_usage_sets from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :edit, vehicle_usage_sets(:vehicle_usage_set_one)
    assert ability.can? :update, vehicle_usage_sets(:vehicle_usage_set_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, vehicle_usage_sets(:vehicle_usage_set_one)
    sign_in users(:user_three)
    get :edit, id: @vehicle_usage_set
    assert_response :redirect
  end

  test 'should get index vehicle_usage_set' do
    get :index
    assert_response :success
    assert_not_nil assigns(:vehicle_usage_sets)
    assert_valid response
  end

  test 'should get new vehicle_usage_set' do
    get :new
    assert_response :success
    assert_valid response
  end

  test 'should create vehicle_usage_set' do
    assert_difference('VehicleUsageSet.count') do
      assert_difference('VehicleUsage.count', customers(:customer_one).vehicles.length) do
        post :create, vehicle_usage_set: { name: @vehicle_usage_set.name }
      end
    end

    assert_redirected_to vehicle_usage_sets_path
  end

  test 'should not create vehicle_usage_set' do
    assert_difference('VehicleUsageSet.count', 0) do
      post :create, vehicle_usage_set: { name: '' }
    end

    assert_template :new
    vehicle_usage_set = assigns(:vehicle_usage_set)
    assert vehicle_usage_set.errors.any?
    assert_valid response
  end

  test 'should get edit vehicle_usage_set' do
    get :edit, id: @vehicle_usage_set
    assert_response :success
    assert_valid response
  end

  test 'should update vehicle_usage_set' do
    patch :update, id: @vehicle_usage_set, vehicle_usage_set: { name: 'toto', open: @vehicle_usage_set.open }
    assert_redirected_to vehicle_usage_sets_path
  end

  test 'should not update vehicle_usage_set' do
    patch :update, id: @vehicle_usage_set, vehicle_usage_set: { name: '' }

    assert_template :edit
    vehicle_usage_set = assigns(:vehicle_usage_set)
    assert vehicle_usage_set.errors.any?
    assert_valid response
  end

  test 'should destroy vehicle_usage_set' do
    assert_difference('VehicleUsageSet.count', -1) do
      delete :destroy, id: @vehicle_usage_set
    end

    assert_redirected_to vehicle_usage_sets_path
  end

  test 'should destroy multiple vehicle_usage_set' do
    assert_difference('VehicleUsageSet.count', -1) do
      delete :destroy_multiple, vehicle_usage_sets: { vehicle_usage_sets(:vehicle_usage_set_one).id => 1 }
    end

    assert_redirected_to vehicle_usage_sets_path
  end

  test 'should destroy multiple vehicle_usage_set, 0 item' do
    assert_difference('VehicleUsageSet.count', 0) do
      delete :destroy_multiple
    end

    assert_redirected_to vehicle_usage_sets_path
  end

  test 'should duplicate vehicle_usage_set' do
    assert_difference('VehicleUsageSet.count') do
      patch :duplicate, vehicle_usage_set_id: @vehicle_usage_set
    end

    assert_redirected_to edit_vehicle_usage_set_path(assigns(:vehicle_usage_set))
  end
end
