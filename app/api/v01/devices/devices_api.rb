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
class V01::Devices::DevicesApi < Grape::API
  namespace :devices do
    params do
      requires :device, type: Symbol
    end
    segment '/:device' do

      before do
        current_customer(params[:id]) if @current_user.admin?
      end

      rescue_from DeviceServiceError do |e|
        error! e.message, 200
      end

      desc 'Validate device Credentials',
        detail: 'Validate device Credentials.',
        nickname: 'checkAuth'
      params do
        requires :id, type: Integer, desc: 'Customer ID as we need to get customer devices'
      end
      get 'auth/:id' do
        device = @current_customer.device.enableds[params[:device]]
        if device && device.respond_to?('check_auth')
          device.check_auth(params) # raises DeviceServiceError
          status 204
        else
          status 404
        end
      end

      desc 'Send Route',
        detail: 'Send Route to device.',
        nickname: 'sendRoute'
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
        optional :type, type: Symbol, desc: 'Action Name'
      end
      post 'send' do
        device = @current_customer.device.enableds[params[:device]]
        if device && device.respond_to?('send_route')
          Route.transaction do
            route = Route.for_customer(@current_customer).find params[:route_id]
            device.send_route(@current_customer, route, params.slice(:type))
            route.set_send_to(device.definition[:label_small])
            route.save!
            present route, with: V01::Entities::DeviceRouteLastSentAt
          end
        else
          status 404
        end
      end
    end
  end
end
