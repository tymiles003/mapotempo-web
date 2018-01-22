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
    planning = plannings(:planning_one)
    planning.update!(date: 10.days.from_now)
    planning.routes.select(&:vehicle_usage_id).each do |route|
      route.update!(end: (route.start || 0) + 1.hour)
    end

    @route = routes(:route_one_one)
    @vehicle = @route.vehicle_usage.vehicle
    @vehicle.update!(devices: { fleet_user: 'driver1' })
  end

  def with_stubs(names, &block)
    begin
      stubs = []
      names.each do |name|
        case name
          when :auth
            url = FleetService.new(customer: @customer).service.send(:get_user_url, @customer.devices[:fleet][:user])
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
              user_current_locations: [
                {
                  sync_user: 'driver1',
                  name: 'driver1',
                  location_detail: {
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
            planning_date_hash = planning.date.beginning_of_day.to_i.to_s(36)
            reference_ids = planning.routes.select(&:vehicle_usage?).collect(&:stops).flatten.collect { |stop| (stop.is_a?(StopVisit) ? "mission-v#{stop.visit_id}-#{planning_date_hash}" : "mission-r#{stop.id}-#{planning_date_hash}") }.uniq

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
          when :delete_missions_by_date_url
            planning = plannings(:planning_one)
            planning_date = planning.date ? planning.date.beginning_of_day.to_time : Time.zone.now.beginning_of_day
            planning.routes.select(&:vehicle_usage_id).each do |route|
              start_date = (planning_date + (route.start || 0)).strftime('%Y-%m-%d')
              end_date = (planning_date + (route.end || 0)).strftime('%Y-%m-%d')

              url = FleetService.new(customer: @customer).service.send(:delete_missions_by_date_url, 'driver1', start_date, end_date)
              stubs << stub_request(:delete, url).to_return(status: 204, body: nil)
            end
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
