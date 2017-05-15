require 'test_helper'

class VehicleUsageSetsControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    sign_in users(:user_one)
    assert_valid response
  end

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1000, 60, '_ibE_seK_seK_seK'] } } ) do
      yield
    end
  end

  test 'user can only view vehicle_usage_sets from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :edit, @vehicle_usage_set
    assert ability.can? :update, @vehicle_usage_set
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, @vehicle_usage_set

    get :edit, id: vehicle_usage_sets(:vehicle_usage_set_two)
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

  test 'should create vehicle_usage_set with time exceeding one day' do
    post :create, vehicle_usage_set: { name: 'toto', open: '20:00', close: '08:00', close_day: '1' }
    assert_equal VehicleUsageSet.last.open, 20 * 3_600
    assert_equal VehicleUsageSet.last.close, 32 * 3_600
  end

  test 'should create vehicle_usage_set with default close' do
    post :create, vehicle_usage_set: { name: 'toto', open: '16:00', close_day: '1' }
    assert VehicleUsageSet.last.open, 16 * 3_600
    assert VehicleUsageSet.last.close, 18 * 3_600
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

  test 'should update vehicle_usage_set with time exceeding one day' do
    patch :update, id: @vehicle_usage_set, vehicle_usage_set: { name: 'toto', open: '20:00', close: '08:00', close_day: '1' }
    @vehicle_usage_set.reload
    assert_equal @vehicle_usage_set.open, 20 * 3_600
    assert_equal @vehicle_usage_set.close, 32 * 3_600

    patch :update, id: @vehicle_usage_set, vehicle_usage_set: { name: 'toto', open: '08:00', open_day: '1', close: '12:00', close_day: '1', rest_start: '10:00', rest_start_day: '1', rest_stop: '11:00', rest_stop_day: '1', rest_duration: '01:00' }
    @vehicle_usage_set.reload
    assert_equal @vehicle_usage_set.open, 32 * 3_600
    assert_equal @vehicle_usage_set.close, 36 * 3_600
    assert_equal @vehicle_usage_set.rest_start, 34 * 3_600
    assert_equal @vehicle_usage_set.rest_stop, 35 * 3_600
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
