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

class FleetTest < ActionController::TestCase

  require Rails.root.join('test/lib/devices/fleet_base')
  include FleetBase

  setup do
    @customer = customers(:customer_one)
    @customer.update(devices: { fleet: { enable: true, user: 'test', password: '123456' } }, enable_vehicle_position: true, enable_stop_status: true)
    @service = Mapotempo::Application.config.devices.fleet
  end

  test 'should check authentication' do
    with_stubs [:auth] do
      params = {
        user: @customer.devices[:fleet][:user],
        password: @customer.devices[:fleet][:password]
      }
      assert @service.check_auth(params)
    end
  end

  test 'should check no authentication' do
    assert_raise do
      @service.check_auth({})
    end
  end

  test 'should get list of vehicles' do
    with_stubs [:get_users_url] do
      response = @service.list_devices(@customer)
      assert_kind_of Array, response
      assert response.all? { |v| v[:id] && v[:text] }
    end
  end

  test 'should get vehicles positions' do
    with_stubs [:get_vehicles_pos_url] do
      response = @service.get_vehicles_pos(@customer)
      assert_kind_of Array, response
      assert response.all? { |v| v[:fleet_vehicle_id] && v[:device_name] && v[:lat] && v[:lng] }
    end
  end

  test 'should get stop status' do
    with_stubs [:fetch_stops] do
      planning = plannings(:planning_one)
      planning.routes.select(&:vehicle_usage_id).each { |route|
        route.last_sent_at = Time.now.utc
      }
      planning.save

      planning.fetch_stops_status
      planning.routes.select(&:vehicle_usage_id).each { |route|
        if route.ref == 'route_one'
          assert route.stops.select(&:active).any? { |stop| stop.status == 'Planned' }
          assert route.stops.select(&:active).any? { |stop| stop.status == 'Finished' }
        end
      }
    end
  end

  test 'should send route' do
    set_route
    with_stubs [:set_missions_url] do
      assert_nothing_raised do
        assert @service.send_route(@customer, routes(:route_one_one))
      end
    end
  end

  test 'should clear route' do
    set_route
    with_stubs [:delete_missions_by_date_url] do
      assert_nothing_raised do
        @service.clear_route(@customer, routes(:route_one_one))
      end
    end
  end
end
