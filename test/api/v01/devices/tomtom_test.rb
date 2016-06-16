# Copyright © Mapotempo, 2016
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'test_helper'

class V01::Devices::TomtomTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  require Rails.root.join("test/lib/devices/api_base")
  include ApiBase

  require Rails.root.join("test/lib/devices/tomtom_base")
  include TomtomBase

  setup do
    @customer = add_tomtom_credentials customers(:customer_one)
  end

  test 'authenticate' do
    with_stubs [:client_objects_wsdl, :object_report] do
      get api("devices/tomtom/auth")
      assert_equal 204, last_response.status
    end
  end

  test 'list devices' do
    with_stubs [:client_objects_wsdl, :object_report] do
      get api("devices/tomtom/devices", { customer_id: @customer.id })
      assert_equal 200, last_response.status
      assert_equal [
        {"id"=>"1-44063-666E054E7", "text"=>"MAPO1"},
        {"id"=>"1-44063-666F24630", "text"=>"MAPO2"}
      ], JSON.parse(last_response.body)
    end
  end

  test 'vehicle positions' do
    with_stubs [:client_objects_wsdl, :object_report] do
      set_route
      get api("vehicles/current_position"), { ids: @customer.vehicle_ids }
      assert_equal 200, last_response.status
      assert_equal [{
        "vehicle_id"=>@vehicle.id,
        "device_name"=>"MAPO2",
        "lat"=>46.36204,
        "lng"=>6.475177,
        "direction"=>"227",
        "speed"=>"21",
        "time"=>"2016-02-10T07:38:33.000+00:00",
      }], JSON.parse(last_response.body)
    end
  end

  test 'send orders' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      post api("devices/tomtom/send", { customer_id: @customer.id, route_id: @route.id, type: "orders" })
      assert_equal 201, last_response.status
      @route.reload
      assert @route.reload.last_sent_at
      assert_equal({ "id" => @route.id, "last_sent_at" => @route.last_sent_at.iso8601(3) }, JSON.parse(last_response.body))
    end
  end

  test 'send waypoints' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      post api("devices/tomtom/send", { customer_id: @customer.id, route_id: @route.id, type: "waypoints" })
      assert_equal 201, last_response.status
      @route.reload
      assert @route.reload.last_sent_at
      assert_equal({ "id" => @route.id, "last_sent_at" => @route.last_sent_at.iso8601(3) }, JSON.parse(last_response.body))
    end
  end

  test 'send multiple orders' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      post api("devices/tomtom/send_multiple", { customer_id: @customer.id, planning_id: @route.planning_id, type: "orders" })
      assert_equal 201, last_response.status
      routes = @route.planning.routes.select(&:vehicle_usage).select{|route| route.vehicle_usage.vehicle.tomtom_id }
      routes.each &:reload
      routes.each{|route| assert route.last_sent_at }
      assert_equal(routes.map{|route| { "id" => route.id, "last_sent_at" => route.last_sent_at.iso8601(3) } }, JSON.parse(last_response.body))
    end
  end

  test 'send multiple waypoints' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      post api("devices/tomtom/send_multiple", { customer_id: @customer.id, planning_id: @route.planning_id, type: "waypoints" })
      assert_equal 201, last_response.status
      routes = @route.planning.routes.select(&:vehicle_usage).select{|route| route.vehicle_usage.vehicle.tomtom_id }
      routes.each &:reload
      routes.each{|route| assert route.last_sent_at }
      assert_equal(routes.map{|route| { "id" => route.id, "last_sent_at" => route.last_sent_at.iso8601(3) } }, JSON.parse(last_response.body))
    end
  end

  test 'clear' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      delete api("devices/tomtom/clear", { customer_id: @customer.id, route_id: @route.id })
      assert_equal 200, last_response.status
      @route.reload
      assert !@route.reload.last_sent_at
      assert_equal({ "id" => @route.id, "last_sent_at" => nil }, JSON.parse(last_response.body))
    end
  end

  test 'clear multiple' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      delete api("devices/tomtom/clear_multiple", { customer_id: @customer.id, planning_id: @route.planning_id })
      assert_equal 200, last_response.status
      routes = @route.planning.routes.select(&:vehicle_usage).select{|route| route.vehicle_usage.vehicle.tomtom_id }
      routes.each &:reload
      routes.each{|route| assert !route.last_sent_at }
      assert_equal(routes.map{|route| { "id" => route.id, "last_sent_at" => nil } }, JSON.parse(last_response.body))
    end
  end

  test 'sync' do
    with_stubs [:client_objects_wsdl, :vehicle_report] do
      set_route

      # Customer Already Have Devices
      @customer.vehicles.update_all tomtom_id: "tomtom_id"

      # Reset Vehicle
      default_color = "#004499"
      @vehicle.update! fuel_type: nil, color: default_color
      @customer.vehicles.reload ; @vehicle.reload
      assert_equal "tomtom_id", @vehicle.tomtom_id
      assert !@vehicle.fuel_type
      assert_equal default_color, @vehicle.color

      # Send Request.. Send Credentials As Parameters
      post api("devices/tomtom/sync")
      assert_equal 204, last_response.status

      # Vehicle Should Now Have All Values
      @customer.vehicles.reload ; @vehicle.reload
      assert_equal "1-44063-666E054E7", @vehicle.tomtom_id
      assert_equal "DIESEL", @vehicle.fuel_type
      assert_equal "#0000FF", @vehicle.color # Blue

      # Customer Vehicles Should Have Devices Cleared, Except For The Two TomTom Vehicles
      assert @customer.vehicles.where(tomtom_id: nil).count == (@customer.vehicles.count - 2)
    end
  end

  test 'sync with credentials' do
    with_stubs [:client_objects_wsdl, :vehicle_report] do
      set_route

      # Reset Vehicle
      default_color = "#004499"
      @vehicle.update! tomtom_id: nil, fuel_type: nil, color: default_color
      @vehicle.reload
      assert !@vehicle.tomtom_id
      assert !@vehicle.fuel_type
      assert_equal default_color, @vehicle.color

      # Reset Customer
      @customer.update! tomtom_account: nil, tomtom_user: nil, tomtom_password: nil
      @customer.reload
      tomtom_account, tomtom_user, tomtom_password = @customer.tomtom_account, @customer.tomtom_user, @customer.tomtom_password
      assert !@customer.tomtom_account
      assert !@customer.tomtom_user
      assert !@customer.tomtom_password

      # Send Request.. Send Credentials As Parameters
      post api("devices/tomtom/sync"), { tomtom_account: tomtom_account, tomtom_user: tomtom_user, tomtom_password: tomtom_password }
      assert_equal 204, last_response.status

      # Vehicle Should Now Have All Values
      @vehicle.reload
      assert_equal "1-44063-666E054E7", @vehicle.tomtom_id
      assert_equal "DIESEL", @vehicle.fuel_type
      assert_equal "#0000FF", @vehicle.color # Blue
    end
  end

  test 'list addresses' do
    with_stubs [:address_service_wsdl, :address_service] do
      assert_equal 4, @customer.destinations.reload.length
      put api("destinations", { remote: 'tomtom' })
      assert_equal 5, @customer.destinations.reload.length
    end
  end

end
