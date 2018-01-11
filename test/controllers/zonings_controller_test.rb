require 'test_helper'

class ZoningsControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @zoning = zonings(:zoning_one)
    sign_in users(:user_one)
  end

  test 'user can only view zonings from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, @zoning
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, @zoning

    get :edit, id: zonings(:zoning_three)
    assert_response :not_found
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

  test 'should not set @planning.zoning_outdated to true when modifying not relevant zone fields' do
    patch :update, id: @zoning.id, zoning: { name: @zoning.name, zones_attributes: [{ id: @zoning.zones.first.id, name: 'ZoneName' }] }
    assert_equal @zoning.plannings.map(&:zoning_outdated), [nil, nil]
  end

  test 'should not set @planning.zoning_outdated to true when modifying zonning name field' do
    patch :update, id: @zoning.id, zoning: { name: 'ZonningName' }
    assert_equal @zoning.plannings.map(&:zoning_outdated), [nil, nil]
  end

  test 'should set @planning.zoning_outdated to true when modifying relevant zone field: vehicle' do
    vehicle_id = Vehicle.where(customer_id: @zoning.customer_id).second.id
    patch :update, id: @zoning.id, zoning: { name: @zoning.name, zones_attributes: [{ id: @zoning.zones.first.id, vehicle_id: vehicle_id}] }
    assert_equal @zoning.plannings.map(&:zoning_outdated), [true, true]
  end

  test 'should set @planning.zoning_outdated to true when modifying relevant zone field: polygon' do
    polygon = JSON.parse @zoning.zones.first.polygon
    polygon['geometry']['coordinates'][0][0] = [-0.2, 40]
    patch :update, id: @zoning.id, zoning: { name: @zoning.name, zones_attributes: [{ id: @zoning.zones.first.id, polygon: JSON.generate(polygon)}] }
    assert_equal @zoning.plannings.map(&:zoning_outdated), [true, true]
  end

  test 'should set @planning.zoning_outdated to true when modifying relevant zone field: speed_multiplicator' do
    speed_multiplicator = 0
    patch :update, id: @zoning.id, zoning: { name: @zoning.name, zones_attributes: [{ id: @zoning.zones.first.id, avoid_zone: true, speed_multiplicator: speed_multiplicator}] }
    assert_equal @zoning.plannings.map(&:zoning_outdated), [true, true]
  end

  test 'should not create zoning' do
    assert_difference('Zoning.count', 0) do
      assert_difference('Zone.count', 0) do
        post :create, zoning: { name: '', zones_attributes: [Zone.new(name: 'zone').attributes] }
      end
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

  test 'should generate isochrone and isodistance' do
    store_one = stores(:store_one)
    [:isochrone, :isodistance].each { |isowhat|
      uri_template = Addressable::Template.new('localhost:5000/0.1/isoline.json')
      stub_table = stub_request(:post, uri_template)
        .with(:body => hash_including(dimension: (isowhat == :isochrone ? 'time' : 'distance'), loc: "#{store_one.lat},#{store_one.lng}", mode: 'car', size: isowhat == :isochrone ? '600' : '1000'))
        .to_return(File.new(File.expand_path('../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
      patch isowhat, format: :json, vehicle_usage_set_id: vehicle_usage_sets(:vehicle_usage_set_one).id, zoning_id: @zoning
      assert_response :success
      assert_equal 1, JSON.parse(response.body)['zoning'].length
      assert_not_nil JSON.parse(response.body)['zoning'][0]['polygon']
    }
  end

  test 'should use limitation' do
    customer = @zoning.customer
    customer.zonings.delete_all
    customer.max_zonings = 1
    customer.save!

    assert_difference('Zoning.count', 1) do
      post :create, zoning: {
        name: 'new dest',
      }
      assert_response :redirect
    end

    assert_difference('Zoning.count', 0) do
      assert_difference('Zone.count', 0) do
        post :create, zoning: {
          name: 'new 2',
          zones_attributes: [Zone.new(name: 'zone').attributes]
        }
      end
    end
  end
end
