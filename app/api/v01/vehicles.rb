# Copyright © Mapotempo, 2014-2015
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
class V01::Vehicles < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle] if p.key?(:vehicle)
      p.permit(:name, :emission, :consumption, :capacity, :color, :open, :close, :tomtom_id, :store_start_id, :store_stop_id, :router_id)
    end
  end

  resource :vehicles do
    desc 'Fetch customer\'s vehicles.', {
      nickname: 'getVehicles',
      is_array: true,
      entity: V01::Entities::Vehicle
    }
    get do
      present current_customer.vehicles.load, with: V01::Entities::Vehicle
    end

    desc 'Fetch vehicle.', {
      nickname: 'getVehicle',
      entity: V01::Entities::Vehicle
    }
    params {
      requires :id, type: Integer
    }
    get ':id' do
      present current_customer.vehicles.find(params[:id]), with: V01::Entities::Vehicle
    end

    desc 'Update vehicle.', {
      nickname: 'updateVehicle',
      params: V01::Entities::Vehicle.documentation.except(:id),
      entity: V01::Entities::Vehicle
    }
    params {
      requires :id, type: Integer
    }
    put ':id' do
      vehicle = current_customer.vehicles.find(params[:id])
      vehicle.update(vehicle_params)
      vehicle.save!
      present vehicle, with: V01::Entities::Vehicle
    end
  end
end
