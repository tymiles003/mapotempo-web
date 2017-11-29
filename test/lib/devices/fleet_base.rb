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
module FleetBase

  def set_route
    @route = routes(:route_one_one)
    @route.update!(end: @route.start + 5.hours)
    @route.planning.update!(date: 10.days.from_now)
    @vehicle = @route.vehicle_usage.vehicle
    @vehicle.update!(devices: { fleet_user: 'driver1' })
  end

  def with_stubs(names, &block)
    begin
      stubs = []
      names.each do |name|
        case name
          when :auth
            params = {
              user: @customer.devices[:fleet][:user],
              password: @customer.devices[:fleet][:password]
            }
            url = FleetService.new(customer: @customer).service.send(:get_user_url, params)
            expected_response = {
              user: @customer.devices[:fleet][:user]
            }.to_json
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :get_users_url
            url = FleetService.new(customer: @customer).service.send(:get_users_url, with_vehicle: true)
            expected_response = {
              users: [
                {
                  sync_user: 'driver1',
                  email: 'driver1@mapotempo.com',
                  color: '#000'
                },
                {
                  sync_user: 'driver2',
                  email: 'driver2@mapotempo.com'
                }
              ]
            }.to_json
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :get_vehicles_pos_url
            url = FleetService.new(customer: @customer).service.send(:get_vehicles_pos_url)
            expected_response = {
              current_locations: [
                {
                  sync_user: 'driver1',
                  locationDetail: {
                    lat: 40.2,
                    lon: 4.5,
                    time: '20.11.2017',
                    speed: 30,
                  }
                }
              ]
            }.to_json
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :fetch_stops
            planning = plannings(:planning_one)
            reference_ids = planning.routes.select(&:vehicle_usage?).collect(&:stops).flatten.collect { |stop| (stop.is_a?(StopVisit) ? "v#{stop.visit_id}" : "r#{stop.id}") }.uniq

            url = FleetService.new(customer: @customer).service.send(:get_missions_url)
            expected_response = {
              missions: [
                {
                  external_ref: reference_ids[2],
                  status_type_label: 'To do',
                  status_type_color: '#fff'
                },
                {
                  external_ref: reference_ids[3],
                  status_type_label: 'Completed',
                  status_type_color: '#000'
                }
              ]
            }.to_json
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :set_missions_url
            url = FleetService.new(customer: @customer).service.send(:set_missions_url, 'driver1')
            expected_response = {
              missions: [
              ]
            }.to_json
            stubs << stub_request(:post, url).to_return(status: 200, body: expected_response)
          when :delete_missions_url
            route = routes(:route_one_one)
            destination_ids = route.stops.collect { |stop| 'mission-' + (stop.is_a?(StopVisit) ? "v#{stop.visit_id}" : "r#{stop.id}") }

            url = FleetService.new(customer: @customer).service.send(:delete_missions_url, 'driver1', destination_ids)
            stubs << stub_request(:delete, url).to_return(status: 204, body: nil)
        end
      end
      yield
    ensure
      stubs.each do |name|
        remove_request_stub name
      end
    end
  end
end
