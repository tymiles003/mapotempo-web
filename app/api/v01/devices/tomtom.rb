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
class V01::Devices::Tomtom < Grape::API
  namespace :devices do
    namespace :tomtom do

      before do
        @customer = current_customer
      end

      rescue_from DeviceServiceError do |e|
        error! e.message, 200
      end

      desc 'Validate TomTom WebFleet Credentials', detail: 'Validate TomTom WebFleet Credentials'
      get '/auth' do
        tomtom_authenticate @customer
        status 200
      end

      desc 'List Devices', detail: 'List Devices'
      get '/devices' do
        Tomtom.fetch_devices(@customer).map do |item|
          { id: item[:objectUid], text: item[:objectName] }
        end
      end

      desc 'Send Route', detail: 'Send Route'
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
        requires :type, type: String, desc: 'Action Name'
      end
      post '/send' do
        route = Route.for_customer(@customer).find params[:route_id]
        case params[:type]
          when 'waypoints'
            Tomtom.export_route_as_waypoints route
          when 'orders'
            Tomtom.export_route_as_orders route
        end
        status 200
      end

     desc 'Send Planning Routes', detail: 'Send Planning Routes'
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
        requires :type, type: String, desc: 'Action Name'
      end
      post '/send_multiple' do
        planning = @customer.plannings.find params[:planning_id]
        planning.routes.select(&:vehicle_usage).each do |route|
          next if route.vehicle_usage.vehicle.tomtom_id.blank?
          case params[:type]
            when 'waypoints'
              Tomtom.export_route_as_waypoints route
            when 'orders'
              Tomtom.export_route_as_orders route
          end
        end
        status 200
      end

      desc 'Clear Route', detail: 'Clear Route'
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
      end
      delete '/clear' do
        route = Route.for_customer(@customer).find params[:route_id]
        Tomtom.clear route
        status 200
      end

      desc 'Clear Planning Routes', detail: 'Clear Planning Routes'
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      delete '/clear_multiple' do
        planning = @customer.plannings.find params[:planning_id]
        planning.routes.select(&:vehicle_usage).each do |route|
          next if route.vehicle_usage.vehicle.tomtom_id.blank?
          Tomtom.clear route
        end
        status 200
      end

      desc 'Sync Vehicles', detail: 'Sync Vehicles'
      post '/sync' do
        tomtom_sync_vehicles @customer
        status 200
      end

    end
  end
end
