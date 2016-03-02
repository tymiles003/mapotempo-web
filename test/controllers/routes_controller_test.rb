require 'test_helper'

require 'rexml/document'
include REXML

class RoutesControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @route = routes(:route_one_one)
    sign_in users(:user_one)
  end

  test 'user can only view routes from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, routes(:route_one_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, routes(:route_one_one)
    sign_in users(:user_three)
    get :show, id: @route
    assert_response :redirect
  end

  test 'should show route' do
    get :show, id: @route
    assert_response :success
    assert_valid response
  end

  test 'should show route as csv' do
    get :show, id: @route, type: :csv
    assert_response :success
  end

  test 'should show route as excel' do
    get :show, id: @route, format: :excel
    assert_response :success
  end

  test 'should show route as gpx' do
    get :show, id: @route, format: :gpx
    assert_response :success
    assert Document.new(response.body)
  end

  test 'should show route as kml' do
    get :show, id: @route, format: :kml
    assert_response :success
    assert Document.new(response.body)
  end

  test 'should show route as kmz' do
    get :show, id: @route, format: :kmz
    assert_response :success
  end

  test 'should show route as kmz by email' do
    get :show, id: @route, format: :kmz, email: 1
    assert_response :success
  end

  test 'should show route for masternaut' do
    Masternaut.class_eval do
      def self.save_export_route(route)
        self.export_route(route)
      end
      def self.export_route(route)
        true
      end
    end
    get :show, id: @route, format: :masternaut
    assert_response :success
    assert Document.new(response.body)
    Masternaut.class_eval do
      def self.export_route(route)
        self.save_export_route(route)
      end
    end
  end

  test 'should show route for alyacom' do
    Alyacom.class_eval do
      def self.save_export_route(route)
        self.export_route(route)
      end
      def self.export_route(route)
        true
      end
    end
    get :show, id: @route, format: :alyacom
    assert_response :success
    Alyacom.class_eval do
      def self.export_route(route)
        self.save_export_route(route)
      end
    end
  end

  test 'should update route' do
    patch :update, id: @route, route: { hidden: @route.hidden, locked: @route.locked, ref: 'ref8' }
    assert_redirected_to route_path(assigns(:route))
  end
end
