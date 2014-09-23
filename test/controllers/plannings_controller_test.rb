require 'test_helper'

require 'rexml/document'
include REXML

class PlanningsControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    def Trace.compute(url, from_lat, from_lng, to_lat, to_lng)
      [1000, 60, "trace"]
    end

    def Ort.optimize(capacity, matrix, time_window)
      (0..(matrix.size-1)).to_a
    end

    @planning = plannings(:planning_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:plannings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create planning" do
    assert_difference('Planning.count') do
      post :create, planning: { name: @planning.name, zoning_id: @planning.zoning.id }
    end

    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should not create planning" do
    assert_difference('Planning.count', 0) do
      post :create, planning: { name: "" }
    end

    assert_template :new
    planning = assigns(:planning)
    assert planning.errors.any?
  end

  test "should show planning" do
    get :show, id: @planning
    assert_response :success
  end

  test "should show planning as excel" do
    get :show, id: @planning, format: :excel
    assert_response :success
  end

  test "should show planning as gpx" do
    get :show, id: @planning, format: :gpx
    assert_response :success
    assert Document.new(response.body)
  end

  test "should show planning as csv" do
    get :show, id: @planning, format: :csv
    assert_response :success
    assert_equal ',,,,a,unaffected_one,MyString,MyString,MyString,MyString,1.5,1.5,MyString,00:01:00,1,,10:00,11:00,tag1,"","",""', response.body.split("\n")[1]
    assert_equal 'vehicle_one,2,00:00,1.5,c,destination_two,MyString,MyString,MyString,MyString,1.5,1.5,MyString,,3,1,10:00,11:00,tag1,"","",""', response.body.split("\n").select{ |l| l.include?('vehicle_one') }[2]
  end

  test "should get edit" do
    get :edit, id: @planning
    assert_response :success
  end

  test "should update planning" do
    patch :update, id: @planning, planning: { name: @planning.name, zoning_id: @planning.zoning.id }
    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should update planning and change zoning" do
    patch :update, id: @planning, planning: { zoning_id: zonings(:zoning_two).id }
    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should not update planning" do
    patch :update, id: @planning, planning: { name: "" }

    assert_template :edit
    planning = assigns(:planning)
    assert planning.errors.any?
  end

  test "should destroy planning" do
    assert_difference('Planning.count', -1) do
      delete :destroy, id: @planning
    end

    assert_redirected_to plannings_path
  end

  test "should move" do
    patch :move, planning_id: @planning, format: :json, planning: { name: @planning.name, zoning_id: @planning.zoning.id }
    assert_response :success
  end

  test "should refresh" do
    get :refresh, planning_id: @planning, format: :json
    assert_response :success
  end

  test "should refresh zoning" do
    @planning.zoning_out_of_date = true
    @planning.save!
    get :refresh, planning_id: @planning, format: :json
    assert_response :success
    planning = assigns(:planning)
    assert_not planning.zoning_out_of_date
  end

  test "should switch" do
    patch :switch, planning_id: @planning, format: :json, route_id: routes(:route_one).id, vehicle_id: vehicles(:vehicle_one).id
    assert_response :success, id: @planning
  end

  test "should not switch" do
    patch :switch, planning_id: @planning, format: :json, route_id: routes(:route_one).id, vehicle_id: 666
    assert_response :unprocessable_entity
  end

  test "should update stop" do
    patch :update_stop, planning_id: @planning, format: :json, route_id: routes(:route_one).id, destination_id: destinations(:destination_one).id, stop: { active: false }
    assert_response :success
  end

  test "should optimize route" do
    get :optimize_route, planning_id: @planning, format: :json, route_id: routes(:route_one).id
    assert_response :success
  end

  test "should duplicate" do
    assert_difference('Planning.count') do
      patch :duplicate, planning_id: @planning
    end

    assert_redirected_to edit_planning_path(assigns(:planning))
  end

  test "should automatic insert" do
    patch :automatic_insert, planning_id: @planning, format: :json, destination_id: destinations(:destination_unaffected_one).id
    assert_response :success
  end
end
