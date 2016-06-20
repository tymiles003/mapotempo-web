require 'test_helper'

require 'rexml/document'
include REXML

require 'optim/ort'

class PlanningsControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @planning = plannings(:planning_one)
    sign_in users(:user_one)
    customers(:customer_one).update(job_optimizer_id: nil, job_destination_geocoding_id: nil)
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      Routers::Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
        Ort.stub_any_instance(:optimize, lambda { |matrix, dimension, services, stores, rests, optimize_time, soft_upper_bound, cluster_time_threshold| (0..(matrix.size-1)).to_a }) do
          yield
        end
      end
    end
  end

  test 'user can only view plannings from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, plannings(:planning_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, plannings(:planning_one)
    sign_in users(:user_three)
    get :edit, id: @planning
    assert_response :redirect
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:plannings)
    assert_valid response
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_valid response
  end

  test 'Create Planning' do
    # EN
    I18n.locale = I18n.default_locale = :en
    assert_equal :en, I18n.locale
    assert_difference('Planning.count') do
      post :create, planning: { name: @planning.name, vehicle_usage_set_id: vehicle_usage_sets(:vehicle_usage_set_one).id, zoning_ids: @planning.zonings.collect(&:id), date: '10-30-2016' }
    end
    assert_redirected_to edit_planning_path(assigns(:planning))
    assert assigns(:planning).persisted?
    assert assigns(:planning).date.strftime("%d-%m-%Y") == '30-10-2016'

    # FR
    I18n.locale = I18n.default_locale = :fr
    assert_equal :fr, I18n.locale
    assert_difference('Planning.count') do
      post :create, planning: { name: @planning.name, vehicle_usage_set_id: vehicle_usage_sets(:vehicle_usage_set_one).id, zoning_ids: @planning.zonings.collect(&:id), date: '30-10-2016' }
    end
    assert_redirected_to edit_planning_path(assigns(:planning))
    assert assigns(:planning).persisted?
    assert assigns(:planning).date.strftime("%d-%m-%Y") == '30-10-2016'
  end

  test 'Update Planning' do
    # EN
    I18n.locale = I18n.default_locale = :en
    assert_equal :en, I18n.locale
    patch :update, id: @planning, planning: { name: @planning.name, zoning_ids: @planning.zonings.collect(&:id), date: '10-30-2016' }
    assert_redirected_to edit_planning_path(assigns(:planning))
    assert assigns(:planning).persisted?
    assert assigns(:planning).date.strftime("%d-%m-%Y") == '30-10-2016'

    # FR
    I18n.locale = I18n.default_locale = :fr
    assert_equal :fr, I18n.locale
    patch :update, id: @planning, planning: { name: @planning.name, zoning_ids: @planning.zonings.collect(&:id), date: '30-10-2016' }
    assert_redirected_to edit_planning_path(assigns(:planning))
    assert assigns(:planning).persisted?
    assert assigns(:planning).date.strftime("%d-%m-%Y") == '30-10-2016'
  end

  test 'should not create planning' do
    assert_difference('Planning.count', 0) do
      post :create, planning: { name: '' }
    end

    assert_template :new
    planning = assigns(:planning)
    assert planning.errors.any?
    assert_valid response
  end

  test 'should show planning' do
    get :show, id: @planning
    assert_response :success
    assert_valid response
  end

  test 'should show planning as json' do
    get :show, format: :json, id: @planning
    assert_response :success
    assert_equal 3, JSON.parse(response.body)['routes'].size
  end

  test 'should show planning as excel' do
    get :show, id: @planning, format: :excel
    assert_response :success
  end

  test 'should show planning as csv with order array' do
    o = plannings(:planning_one)
    oa = order_arrays(:order_array_one)
    o.apply_orders(oa, 0)
    o.save!

    get :show, id: @planning, format: :csv
    assert_response :success
    assert_equal 'route_zero,,,visite,,,,,,"","","",a,unaffected_one,MyString,MyString,MyString,MyString,,1.5,1.5,MyString,MyString,tag1,a,00:01:00,,10:00,11:00,tag1', response.body.split("\n")[1]
    assert_equal 'route_one,001,1,visite,1,,00:00,1.1,,"","","",b,destination_one,Rue des Lilas,MyString,33200,Bordeau,,49.1857,-0.3735,MyString,MyString,"",b,00:05:33,P1/P2,10:00,11:00,tag1', response.body.split("\n").select{ |l| l.include?('001') }[1]
  end

  test 'should show planning as csv with ordered columns' do
    get :show, id: @planning, format: :csv, stops: 'visit', columns: 'route|name|street|postalcode|city'
    assert_response :success
    assert_equal 'route_three,destination_one,Rue des Lilas,33200,Bordeau', response.body.split("\n")[1]
  end

  test 'should show planning as gpx' do
    get :show, id: @planning, format: :gpx
    assert_response :success
    assert Document.new(response.body)
  end

  test 'should show planning as kml' do
    get :show, id: @planning, format: :kml
    assert_response :success
    assert Document.new(response.body)
  end

  test 'should show planning as kmz' do
    get :show, id: @planning, format: :kmz
    assert_response :success
  end

  test 'should show planning as kmz by email' do
    get :show, id: @planning, format: :kmz, email: 1
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @planning
    assert_response :success
    assert_valid response
  end

  test 'should update planning and change zoning' do
    patch :update, id: @planning, planning: { zoning_id: zonings(:zoning_two).id }
    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test 'should not update planning' do
    patch :update, id: @planning, planning: { name: '' }

    assert_template :edit
    planning = assigns(:planning)
    assert planning.errors.any?
    assert_valid response
  end

  test 'should destroy planning' do
    assert_difference('Planning.count', -1) do
      delete :destroy, id: @planning
    end

    assert_redirected_to plannings_path
  end

  test 'should destroy multiple planning' do
    assert_difference('Planning.count', -2) do
      delete :destroy_multiple, plannings: { plannings(:planning_one).id => 1, plannings(:planning_two).id => 1 }
    end

    assert_redirected_to plannings_path
  end

  test 'should move' do
    patch :move, planning_id: @planning, route_id: @planning.routes[1], stop_id: @planning.routes[0].stops[0], index: 1, format: :json
    assert_response :success
    assert_equal 2, JSON.parse(response.body)['routes'].size
  end

  test 'should move with error' do
    Route.stub_any_instance(:compute, lambda{ |*a| raise }) do
      assert_no_difference('Stop.count') do
        assert_raise do
          patch :move, planning_id: @planning, route_id: @planning.routes[1], stop_id: @planning.routes[0].stops[0], index: 1, format: :json
        end
      end
    end
  end

  test 'should move with automatic index' do
    patch :move, planning_id: @planning, route_id: @planning.routes[1], stop_id: @planning.routes[0].stops[0], format: :json
    assert_response :success
    assert_equal 2, JSON.parse(response.body)['routes'].size
  end

  test 'should not move' do
    patch :move, planning_id: @planning, route_id: @planning.routes[1], stop_id: @planning.routes[0].stops[0], index: 666, format: :json
    planning = assigns(:planning)
    assert planning.errors.any?
    assert_valid response
    assert_response 422
  end

  test 'should not move stop to route with deactivated vehicle' do
    route = @planning.routes.joins(:vehicle_usage).take
    route.vehicle_usage.update! active: !route.vehicle_usage.active?
    out_of_route = @planning.routes.detect{|route| !route.vehicle_usage }
    stop = out_of_route.stops.take
    assert_raises do
      patch :move, planning_id: @planning.id, route_id: route.id, stop_id: stop.id, index: 1, format: :json
    end
    assert stop.reload.route == out_of_route
  end

  test 'should refresh' do
    get :refresh, planning_id: @planning, format: :json
    assert_response :success
  end

  test 'should refresh zoning' do
    @planning.zoning_out_of_date = true
    @planning.save!
    get :refresh, planning_id: @planning, format: :json
    assert_response :success
    planning = assigns(:planning)
    assert_not planning.zoning_out_of_date
  end

  test 'should switch with same vehicle' do
    patch :switch, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id, vehicle_usage_id: vehicle_usages(:vehicle_usage_one_one).id
    assert_response :success, id: @planning
    assert_equal 1, JSON.parse(response.body)['routes'].size
  end

  test 'should switch' do
    patch :switch, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id, vehicle_usage_id: vehicle_usages(:vehicle_usage_one_three).id
    assert_response :success, id: @planning
    assert_equal 2, JSON.parse(response.body)['routes'].size
  end

  test 'should not switch' do
    assert_raises ActiveRecord::RecordNotFound do
      patch :switch, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id, vehicle_usage_id: 666
    end
  end

  test 'should update stop' do
    patch :update_stop, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id, stop_id: stops(:stop_one_one).id, stop: { active: false }
    assert_response :success
    assert_equal 1, JSON.parse(response.body)['routes'].size
  end

  test 'should optimize route' do
    get :optimize_route, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id
    assert_response :success
    assert_equal 1, JSON.parse(response.body)['routes'].size
  end

  test 'should duplicate' do
    assert_difference('Planning.count') do
      patch :duplicate, planning_id: @planning
    end

    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test 'Automatic Insert' do
    patch :automatic_insert, id: @planning.id, format: :json, stop_ids: [stops(:stop_unaffected).id]
    assert_response :success
    assert_equal 2, assigns(:routes).length
    routes = JSON.parse(response.body)['routes']
    assert_equal 2, routes.size
    assert_equal [], routes.first['stops']
  end

  test 'Automatic Insert With Bad IDs' do
    patch :automatic_insert, id: @planning.id, format: :json, stop_ids: [1234]
    assert response.code.to_i == 422
  end

  test 'Automatic Insert All Unaffected Stops' do
    assert @planning.routes.detect{|route| !route.vehicle_usage }.stops.any?
    patch :automatic_insert, id: @planning.id, format: :json, stop_ids: []
    assert_response :success
    assert @planning.routes.detect{|route| !route.vehicle_usage }.stops.reload.none?
  end

  test 'should update active' do
    patch :active, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id, active: :none
    assert_response :success
    assert_equal 1, JSON.parse(response.body)['routes'].size
  end

  test 'should reverse route stops' do
    patch :reverse_order, planning_id: @planning, format: :json, route_id: routes(:route_one_one).id
    assert_response :success
    assert_equal 1, JSON.parse(response.body)['routes'].size
  end
end
