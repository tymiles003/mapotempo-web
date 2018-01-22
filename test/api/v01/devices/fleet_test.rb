# Copyright © Mapotempo, 2017
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

class V01::Devices::FleetTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  require Rails.root.join('test/lib/devices/api_base')
  include ApiBase

  require Rails.root.join('test/lib/devices/fleet_base')
  include FleetBase

  setup do
    @customer = customers(:customer_one)
    @customer.update(devices: { fleet: { enable: true, user: 'driver1', api_key: '123456' } }, enable_vehicle_position: true, enable_stop_status: true)
  end

  def planning_api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings#{part}.json?api_key=testkey1&" + param.collect { |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'authenticate' do
    with_stubs [:auth] do
      get api("devices/fleet/auth/#{@customer.id}", params_for(:fleet, @customer))
      assert_equal 204, last_response.status
    end
  end

  test 'should send route' do
    set_route
    with_stubs [:set_missions_url] do
      route = routes(:route_one_one)
      post api('devices/fleet/send', { customer_id: @customer.id, route_id: route.id })
      assert_equal 201, last_response.status, last_response.body
      route.reload
      assert route.reload.last_sent_at
      assert_equal({ 'id' => route.id, 'last_sent_to' => 'Fleet', 'last_sent_at' => route.last_sent_at.iso8601(3), 'last_sent_at_formatted' => I18n.l(route.last_sent_at) }, JSON.parse(last_response.body))
    end
  end

  test 'list devices' do
    set_route
    with_stubs [:get_users_url] do
      get api('devices/fleet/devices', { customer_id: @customer.id })
      assert_equal 200, last_response.status
      assert JSON.parse(last_response.body).all? { |v| v['id'] && v['text'] }
    end
  end

  test 'should return vehicle positions' do
    set_route
    with_stubs [:get_vehicles_pos_url] do
      get api('vehicles/current_position'), { ids: @customer.vehicle_ids }
      assert_equal 200, last_response.status, last_response.body
      response = JSON.parse(last_response.body)
      assert_equal 1, response.size
      assert response.all? { |v| v['lat'] && v['lng'] }
    end
  end

  test 'should send multiple routes' do
    set_route
    with_stubs [:set_missions_url] do
      planning = plannings(:planning_one)
      post api('devices/fleet/send_multiple', { customer_id: @customer.id, planning_id: planning.id })
      assert_equal 201, last_response.status, last_response.body
      routes = planning.routes.select(&:vehicle_usage_id)
      routes.each(&:reload)
      routes.each { |route|
        assert_equal([{ 'id' => route.id, 'last_sent_to' => 'Fleet', 'last_sent_at' => route.last_sent_at.iso8601(3), 'last_sent_at_formatted' => I18n.l(route.last_sent_at) }], JSON.parse(last_response.body)) if route.ref == 'route_one'
      }
    end
  end

  test 'should clear' do
    set_route
    with_stubs [:delete_missions_by_date_url] do
      route = routes(:route_one_one)
      delete api('devices/fleet/clear', { customer_id: @customer.id, route_id: route.id })
      assert_equal 200, last_response.status
      route.reload
      assert !route.last_sent_at
      assert_equal({ 'id' => route.id, 'last_sent_to' => nil, 'last_sent_at' => nil, 'last_sent_at_formatted' => nil }, JSON.parse(last_response.body))
    end
  end

  test 'should clear multiple' do
    set_route
    with_stubs [:delete_missions_by_date_url] do
      planning = plannings(:planning_one)
      delete api('devices/fleet/clear_multiple', { customer_id: @customer.id, planning_id: planning.id })
      assert_equal 204, last_response.status, last_response.body
      routes = planning.routes.select(&:vehicle_usage_id)
      routes.each(&:reload)
      routes.each { |route| assert !route.last_sent_at }
    end
  end

  test 'fetch stops and update quantities' do
    customers(:customer_one).update(job_optimizer_id: nil)
    with_stubs [:fetch_stops] do
      @customer.update_attribute(:enable_stop_status, true)
      set_route
      planning = @route.planning

      patch planning_api("#{planning.id}/update_stops_status", details: true)
      assert_equal 200, last_response.status

      assert_kind_of Array, JSON.parse(last_response.body)

      planning.routes.select(&:vehicle_usage_id).each { |route|
        if route.ref == 'route_one'
          assert route.stops.select(&:active).any? { |stop| stop.status == 'Planned' }
          assert route.stops.select(&:active).any? { |stop| stop.status == 'Finished' }
        end
      }
    end
  end
end
