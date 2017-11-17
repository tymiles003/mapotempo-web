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

class V01::Devices::FleetDemoTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  require Rails.root.join("test/lib/devices/api_base")
  include ApiBase

  setup do
    @customer = customers(:customer_one)
    @customer.update devices: { fleet_demo: { enable: true } }, enable_vehicle_position: true, enable_stop_status: true
  end

  test 'should return vehicle positions' do
    get api("vehicles/current_position"), { ids: @customer.vehicle_ids }
    assert_equal 200, last_response.status, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal 2, response.size
    assert response.all?{ |v| v['lat'] && v['lng'] }
  end

  test 'should send route' do
    route = routes(:route_one_one)
    post api("devices/fleet_demo/send", { customer_id: @customer.id, route_id: route.id })
    assert_equal 201, last_response.status, last_response.body
    route.reload
    assert route.reload.last_sent_at
    assert_equal({ "id" => route.id, "last_sent_to" => 'Demo', "last_sent_at" => route.last_sent_at.iso8601(3), "last_sent_at_formatted"=>I18n.l(route.last_sent_at) }, JSON.parse(last_response.body))
  end

  # FIXME last_sent_at not updated
  # test 'should send multiple routes' do
  #   planning = plannings(:planning_one)
  #   post api("devices/fleet_demo/send_multiple", { customer_id: @customer.id, planning_id: planning.id })
  #   assert_equal 201, last_response.status, last_response.body
  #   routes = planning.routes.select(&:vehicle_usage_id)
  #   routes.each &:reload
  #   routes.each{ |route| assert route.last_sent_at }
  #   assert_equal(routes.map{ |route| { "id" => route.id, "last_sent_to" => 'Demo', "last_sent_at" => route.last_sent_at.iso8601(3), "last_sent_at_formatted"=>I18n.l(route.last_sent_at) } }, JSON.parse(last_response.body))
  # end

  test 'should clear' do
    route = routes(:route_one_one)
    delete api("devices/fleet_demo/clear", { customer_id: @customer.id, route_id: route.id })
    assert_equal 200, last_response.status
    route.reload
    assert !route.last_sent_at
    assert_equal({ "id" => route.id, "last_sent_to" => nil, "last_sent_at" => nil, "last_sent_at_formatted"=>nil }, JSON.parse(last_response.body))
  end

  test 'should clear multiple' do
    planning = plannings(:planning_one)
    delete api("devices/fleet_demo/clear_multiple", { customer_id: @customer.id, planning_id: planning.id })
    assert_equal 204, last_response.status, last_response.body
    routes = planning.routes.select(&:vehicle_usage_id)
    routes.each &:reload
    routes.each{ |route| assert !route.last_sent_at }
    # assert_equal(routes.map{ |route| { "id" => route.id, "last_sent_to" => nil, "last_sent_at" => nil, "last_sent_at_formatted"=>nil } }, JSON.parse(last_response.body))
  end

  # FIXME api route not found
  # test 'should update stops status' do
  #   planning = plannings(:planning_one)
  #   patch api("plannings/#{planning.id}/update_stop_status", details: true)
  #   assert_equal 200, last_response.status, last_response.body
  # end
end
