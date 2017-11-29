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
class V01::Devices::Fleet < Grape::API
  namespace :devices do
    namespace :fleet do

      helpers do
        def service
          FleetService.new customer: @customer
        end
      end

      before do
        @customer = current_customer(params[:customer_id])
      end

      rescue_from DeviceServiceError do |e|
        error! e.message, 200
      end

      desc 'List Devices',
        detail: 'List Devices',
        nickname: 'deviceFleetList'
      get '/devices' do
        present service.list_devices, with: V01::Entities::DeviceItem
      end

      desc 'Send Planning Routes',
        detail: 'Send Planning Routes',
        nickname: 'deviceFleetSendMultiple'
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      post '/send_multiple' do
        device_send_routes params.slice(:type).merge(device_id: :fleet_user)
      end

      desc 'Clear Route',
        detail: 'Clear Route',
        nickname: 'deviceFleetClear'
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
      end
      delete '/clear' do
        device_clear_route
      end

      desc 'Clear Planning Routes',
        detail: 'Clear Planning Routes',
        nickname: 'deviceFleetClearMultiple'
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      delete '/clear_multiple' do
        device_clear_routes device_id: :fleet_user
        status 204
      end

      desc 'Sync Vehicles',
           detail: 'Sync Vehicles',
           nickname: 'deviceFleetSync'
      post '/sync' do
        fleet_sync_vehicles @customer
        status 204
      end
    end
  end
end
