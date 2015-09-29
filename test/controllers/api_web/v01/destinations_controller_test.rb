require 'test_helper'

class ApiWeb::V01::DestinationsControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @destination = destinations(:destination_one)
    sign_in users(:user_one)
  end

  test 'user can only view destinations from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, destinations(:destination_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, destinations(:destination_one)
    sign_in users(:user_three)
    get :index, ids: destinations(:destination_one).id
    assert_equal 0, assigns(:destinations).count
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_nil assigns(:destinations)
    assert_valid response
  end

  test 'should get index by ids' do
    get :index, ids: [destinations(:destination_one).id, destinations(:destination_two).id].join(',')
    assert_response :success
    assert_equal 2, assigns(:destinations).count
    assert_valid response
  end

  test 'should get index with ref' do
    get :index, 'ids' => 'ref:a'
    assert_response :success
    assert_equal 1, assigns(:destinations).count
    assert_valid response
  end

  test 'should get edit position' do
    get :edit_position, id: @destination
    assert_response :success
    assert_valid response
  end

  test 'should update position' do
    patch :update_position, id: @destination, destination: { lat: 6, lng: 6 }
    assert_redirected_to api_web_v01_edit_position_destination_path(assigns(:destination))
  end
end
