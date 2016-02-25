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
class V01::Devices::Teksat < Grape::API
  namespace :devices do
    namespace :teksat do

      before do
        @customer = current_customer
        teksat_authenticate @customer
      end

      rescue_from DeviceServiceError do |e|
        error! e.message, 200
      end

      desc 'Validate Teksat Credentials', detail: 'Validate Teksat Credentials'
      get '/auth' do
        status 200
      end

      desc 'List Devices', detail: 'List Devices'
      get '/devices' do
        TeksatService.new(customer: @customer, ticket_id: session[:teksat_ticket_id]).list
      end

      desc 'Send Route', detail: 'Send Route'
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
      end
      post '/send' do
        route = Route.for_customer(@customer).find params[:route_id]
        TeksatService.new(customer: @customer, route: route, ticket_id: session[:teksat_ticket_id]).send_route
        status 200
      end

      desc 'Send Planning Routes', detail: 'Send Planning Routes'
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      post '/send_multiple' do
        planning = @customer.plannings.find params[:planning_id]
        planning.routes.select(&:vehicle_usage).each do |route|
          next if route.vehicle_usage.vehicle.teksat_id.blank?
          TeksatService.new(customer: @customer, route: route, ticket_id: session[:teksat_ticket_id]).send_route
        end
        status 200
      end

      desc 'Clear Route', detail: 'Clear Route'
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
      end
      delete '/clear' do
        route = Route.for_customer(@customer).find params[:route_id]
        TeksatService.new(customer: @customer, route: route, ticket_id: session[:teksat_ticket_id]).clear_route
        status 200
      end

      desc 'Clear Planning Routes', detail: 'Clear Planning Routes'
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      delete '/clear_multiple' do
        planning = @customer.plannings.find params[:planning_id]
        planning.routes.select(&:vehicle_usage).each do |route|
          next if route.vehicle_usage.vehicle.teksat_id.blank?
          TeksatService.new(customer: @customer, route: route, ticket_id: session[:teksat_ticket_id]).clear_route
        end
        status 200
      end

      desc 'Sync Vehicles', detail: 'Sync Vehicles'
      post '/sync' do
        teksat_sync_vehicles @customer, session[:teksat_ticket_id]
        status 200
      end

    end
  end
end
