# Copyright © Mapotempo, 2015
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
require 'coerce'

class V01::VehicleUsages < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_usage_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle_usage] if p.key?(:vehicle_usage)
      p.permit(:name, :open, :close, :store_start_id, :store_stop_id, :rest_start, :rest_stop, :rest_duration, :store_rest_id, :active)
    end
  end

  resource :vehicle_usage_sets do
    params do
      requires :vehicle_usage_set_id, type: Integer
    end
    segment '/:vehicle_usage_set_id' do
      resource :vehicle_usages do
        desc 'Fetch customer\'s vehicle_usages.',
          nickname: 'getVehicleUsages',
          is_array: true,
          entity: V01::Entities::VehicleUsageWithVehicle
        params do
          optional :ids, type: Array[Integer], desc: 'Select returned vehicle_usages by id.', coerce_with: CoerceArrayInteger
        end
        get do
          vehicle_usage_set = current_customer.vehicle_usage_sets.where(id: params[:vehicle_usage_set_id]).first
          vehicle_usages = if vehicle_usage_set && params.key?(:ids)
            vehicle_usage_set.vehicle_usages.select{ |vehicle_usage| params[:ids].include?(vehicle_usage.id) }
          else
            vehicle_usage_set.vehicle_usages.load
          end
          if vehicle_usage_set && vehicle_usages
            present vehicle_usages, with: V01::Entities::VehicleUsageWithVehicle
          else
            error! 'VehicleUsageSet or VehicleUsage not found', 404
          end
        end

        desc 'Fetch vehicle_usage.',
          nickname: 'getVehicleUsage',
          entity: V01::Entities::VehicleUsageWithVehicle
        params do
          requires :id, type: Integer
        end
        get ':id' do
          vehicle_usage_set = current_customer.vehicle_usage_sets.where(id: params[:vehicle_usage_set_id]).first
          if vehicle_usage_set
            vehicle_usage = vehicle_usage_set.vehicle_usages.find{ |vehicle_usage| vehicle_usage.id == params[:id] }
            if vehicle_usage
              present vehicle_usage, with: V01::Entities::VehicleUsageWithVehicle
              return
            end
          end
          error! 'VehicleUsageSet or VehicleUsage not found', 404
        end

        desc 'Update vehicle_usage.',
          nickname: 'updateVehicleUsage',
          params: V01::Entities::VehicleUsage.documentation.except(:id, :vehicle_usage_set_id),
          entity: V01::Entities::VehicleUsageWithVehicle
        params do
          requires :id, type: Integer
        end
        put ':id' do
          vehicle_usage_set = current_customer.vehicle_usage_sets.where(id: params[:vehicle_usage_set_id]).first
          if vehicle_usage_set
            vehicle_usage = vehicle_usage_set.vehicle_usages.find{ |vehicle_usage| vehicle_usage.id == params[:id] }
            if vehicle_usage
              vehicle_usage.update! vehicle_usage_params
              present vehicle_usage, with: V01::Entities::VehicleUsageWithVehicle
              return
            end
          end
          error! 'VehicleUsageSet or VehicleUsage not found', 404
        end
      end
    end
  end
end
