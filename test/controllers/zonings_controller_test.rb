require 'test_helper'

class ZoningsControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @zoning = zonings(:zoning_one)
    sign_in users(:user_one)
  end

  test 'user can only view zonings from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, zonings(:zoning_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, zonings(:zoning_one)
    sign_in users(:user_three)
    get :edit, id: @zoning
    assert_response :redirect
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:zonings)
    assert_valid response
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_valid response
  end

  test 'should create zoning' do
    assert_difference('Zoning.count') do
      post :create, zoning: { name: @zoning.name }
    end

    assert_redirected_to edit_zoning_path(assigns(:zoning))
  end

  test 'should not create zoning' do
    assert_difference('Zoning.count', 0) do
      post :create, zoning: { name: '' }
    end

    assert_template :new
    zoning = assigns(:zoning)
    assert zoning.errors.any?
    assert_valid response
  end

  test 'should get edit' do
    get :edit, id: @zoning
    assert_response :success
    assert_valid response
  end

  test 'should update zoning' do
    patch :update, id: @zoning, zoning: { name: @zoning.name }
    assert_redirected_to edit_zoning_path(assigns(:zoning))
  end

  test 'should not update zoning' do
    patch :update, id: @zoning, zoning: { name: '' }

    assert_template :edit
    zoning = assigns(:zoning)
    assert zoning.errors.any?
    assert_valid response
  end

  test 'should destroy zoning' do
    assert_difference('Zoning.count', -1) do
      delete :destroy, id: @zoning
    end

    assert_redirected_to zonings_path
  end

  test 'should destroy multiple zoning' do
    assert_difference('Zoning.count', -2) do
      delete :destroy_multiple, zonings: { zonings(:zoning_one).id => 1, zonings(:zoning_two).id => 1 }
    end

    assert_redirected_to zonings_path
  end

  test 'should destroy multiple zoning, 0 item' do
    assert_difference('Zoning.count', 0) do
      delete :destroy_multiple
    end

    assert_redirected_to zonings_path
  end

  test 'should duplicate' do
    assert_difference('Zoning.count') do
      patch :duplicate, zoning_id: @zoning
    end

    assert_redirected_to edit_zoning_path(assigns(:zoning))
  end

  test 'should generate from planning' do
    patch :from_planning, format: :json, zoning_id: @zoning, planning_id: plannings(:planning_one)
    assert_response :success
  end

  test 'should generate automatic' do
    patch :automatic, format: :json, zoning_id: @zoning, planning_id: plannings(:planning_one)
    assert_response :success
  end

  test 'should generate isochrone' do
    store_one = stores(:store_one)
    uri_template = Addressable::Template.new('localhost:1723/0.1/isochrone?lat=' + store_one.lat.to_s + '&lng=' + store_one.lng.to_s + '&time=600')
    stub_table = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
    patch :isochrone, format: :json, vehicle_usage_set_id: vehicle_usage_sets(:vehicle_usage_set_one).id, zoning_id: @zoning
    assert_response :success
    assert_equal 1, JSON.parse(response.body)['zoning'].length
    assert_not_nil JSON.parse(response.body)['zoning'][0]['polygon']
  end
end
