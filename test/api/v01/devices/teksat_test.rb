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

class V01::Devices::TeksatTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  require Rails.root.join("test/lib/devices/api_base")
  include ApiBase

  require Rails.root.join("test/lib/devices/teksat_base")
  include TeksatBase

  setup do
    @customer = add_teksat_credentials customers(:customer_one)
  end

  test 'authenticate' do
    with_stubs [:auth] do
      get api("devices/teksat/auth")
      assert_equal 204, last_response.status, last_response.body
    end
  end

  test 'list devices' do
    with_stubs [:auth, :get_vehicles] do
      get api("devices/teksat/devices", { customer_id: @customer.id })
      assert_equal 200, last_response.status, last_response.body
      assert_equal [
        {"id"=>"97", "text"=>"FIAT DOBLO - 352848026546057"},
        {"id"=>"98", "text"=>"FIAT DOBLO - 352848026546131"},
        {"id"=>"95", "text"=>"FIAT DOBLO - 352848026626164"},
        {"id"=>"96", "text"=>"FIAT DOBLO - 352848026664710"}
      ], JSON.parse(last_response.body)
    end
  end

  test 'vehicle positions' do
    with_stubs [:auth, :vehicles_pos] do
      set_route
      get api("vehicles/current_position"), { ids: @customer.vehicle_ids }
      assert_equal 200, last_response.status
      assert_equal [{
        "vehicle_id"=>@vehicle.id,
        "device_name"=>"356173064830644",
        "lat"=>"49.1860415",
        "lng"=>"-0.3810453",
        "direction"=>nil,
        "speed"=>"0",
        "time"=>"2016-02-10 14:20:31+00:00",
        "time_formatted"=>"10 février 2016 04:20:31"
      }], JSON.parse(last_response.body)
    end
  end

  test 'send' do
    with_stubs [:auth, :send_route] do
      set_route
      post api("devices/teksat/send", { customer_id: @customer.id, route_id: @route.id })
      assert_equal 201, last_response.status
      @route.reload
      assert @route.reload.last_sent_at
      assert_equal({ "id" => @route.id, "last_sent_to" => 'Teksat', "last_sent_at" => @route.last_sent_at.iso8601(3), "last_sent_at_formatted"=>I18n.l(@route.last_sent_at) }, JSON.parse(last_response.body))
    end
  end

  test 'send multiple' do
    with_stubs [:auth, :send_route] do
      set_route
      post api("devices/teksat/send_multiple", { customer_id: @customer.id, planning_id: @route.planning_id })
      assert_equal 201, last_response.status
      routes = @route.planning.routes.select(&:vehicle_usage).select{|route| route.vehicle_usage.vehicle.devices[:teksat_id] }
      routes.each &:reload
      routes.each{|route| assert route.last_sent_at }
      assert_equal(routes.map{|route| { "id" => route.id, "last_sent_to" => 'Teksat', "last_sent_at" => route.last_sent_at.iso8601(3), "last_sent_at_formatted"=>I18n.l(route.last_sent_at) } }, JSON.parse(last_response.body))
    end
  end

  test 'clear' do
    with_stubs [:auth, :clear_route] do
      set_route
      delete api("devices/teksat/clear", { customer_id: @customer.id, route_id: @route.id })
      assert_equal 200, last_response.status
      @route.reload
      assert !@route.reload.last_sent_at
      assert_equal({ "id" => @route.id, "last_sent_to" => nil, "last_sent_at" => nil, "last_sent_at_formatted"=>nil }, JSON.parse(last_response.body))
    end
  end

  test 'clear multiple' do
    with_stubs [:auth, :clear_route] do
      set_route
      delete api("devices/teksat/clear_multiple", { customer_id: @customer.id, planning_id: @route.planning_id })
      assert_equal 200, last_response.status
      routes = @route.planning.routes.select(&:vehicle_usage).select{|route| route.vehicle_usage.vehicle.devices[:teksat_id] }
      routes.each &:reload
      routes.each{|route| assert !route.last_sent_at }
      assert_equal(routes.map{|route| { "id" => route.id, "last_sent_to" => nil, "last_sent_at" => nil, "last_sent_at_formatted"=>nil } }, JSON.parse(last_response.body))
    end
  end

  test 'sync' do
    with_stubs [:auth, :get_vehicles] do
      set_route

      # Customer Already Have Devices
      @customer.vehicles.update_all devices: {teksat_id: "teksat_id"}

      # Reset Vehicle
      @customer.vehicles.reload ; @vehicle.reload
      assert_equal "teksat_id", @vehicle.devices[:teksat_id]

      # Send Request.. Send Credentials As Parameters
      post api("devices/teksat/sync")
      assert_equal 204, last_response.status

      # Vehicle Should Now Have All Values
      @customer.vehicles.reload ; @vehicle.reload
      assert_equal "97", @vehicle.devices[:teksat_id]
    end
  end
end
