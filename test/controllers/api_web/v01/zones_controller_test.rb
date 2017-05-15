require 'test_helper'

class ApiWeb::V01::ZonesControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @zone = zones(:zone_one)
    sign_in users(:user_one)
  end

  test 'user can only view zones from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :index, @zone
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :index, @zone

    assert @controller.can?(:index, @zone.zoning)
    assert @controller.cannot?(:index, zonings(:zoning_three))

    get :index, zoning_id: zonings(:zoning_three).id
    assert_response :redirect
    assert_nil assigns(:zones)
  end

  test 'should sign in with api_key' do
    sign_out users(:user_one)
    get :index, api_key: 'testkey1', zoning_id: @zone.zoning_id
    assert_response :success
    assert_not_nil assigns(:customer)
  end

  test 'should get zones' do
    get :index, zoning_id: @zone.zoning_id
    assert_response :success
    assert_not_nil assigns(:zones)
    assert_valid response
  end
end
