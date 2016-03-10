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

class V01::VehicleUsageSets < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_usage_set_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle_usage_set] if p.key?(:vehicle_usage_set)
      p.permit(:name, :open, :close, :store_start_id, :store_stop_id, :rest_start, :rest_stop, :rest_duration, :store_rest_id)
    end
  end

  resource :vehicle_usage_sets do
    desc 'Fetch customer\'s vehicle_usage_sets.',
      nickname: 'getVehicleUsageSets',
      is_array: true,
      entity: V01::Entities::VehicleUsageSet
    params do
      optional :ids, type: Array[Integer], desc: 'Select returned vehicle_usage_sets by id.', coerce_with: CoerceArrayInteger
    end
    get do
      vehicle_usage_sets = if params.key?(:ids)
        current_customer.vehicle_usage_sets.select{ |vehicle_usage_set| params[:ids].include?(vehicle_usage_set.id) }
      else
        current_customer.vehicle_usage_sets.load
      end
      present vehicle_usage_sets, with: V01::Entities::VehicleUsageSet
    end

    desc 'Fetch vehicle_usage_set.',
      nickname: 'getVehicleUsageSet',
      entity: V01::Entities::VehicleUsageSet
    params do
      requires :id, type: Integer
    end
    get ':id' do
      present current_customer.vehicle_usage_sets.find(params[:id]), with: V01::Entities::VehicleUsageSet
    end

    desc 'Create vehicle_usage_set.',
      detail: 'Only available if "multi usage set" option is active for current customer. <br>For instance, if customer needs to use its vehicle 2 times per day (morning and evening), he needs 2 VehicleUsageSet called \'Morning\' and \'Evening\'. The new VehicleUsageSet allows to define new default values for VehicleUsage.',
      nickname: 'createVehicleUsageSet',
      params: V01::Entities::VehicleUsageSet.documentation.except(:id).deep_merge(
        name: { required: true },
        open: { required: true },
        close: { required: true },
        store_start_id: { required: true },
        store_stop_id: { required: true }
      ),
      entity: V01::Entities::VehicleUsageSet
    post do
      vehicle_usage_set = current_customer.vehicle_usage_sets.build(vehicle_usage_set_params)
      vehicle_usage_set.save!
      present vehicle_usage_set, with: V01::Entities::VehicleUsageSet
    end

    desc 'Update vehicle_usage_set.',
      nickname: 'updateVehicleUsageSet',
      params: V01::Entities::VehicleUsageSet.documentation.except(:id),
      entity: V01::Entities::VehicleUsageSet
    params do
      requires :id, type: Integer
    end
    put ':id' do
      vehicle_usage_set = current_customer.vehicle_usage_sets.find(params[:id])
      vehicle_usage_set.update! vehicle_usage_set_params
      present vehicle_usage_set, with: V01::Entities::VehicleUsageSet
    end

    desc 'Delete vehicle_usage_set.',
      nickname: 'deleteVehicleUsageSet'
    params do
      requires :id, type: Integer
    end
    delete ':id' do
      current_customer.vehicle_usage_sets.find(params[:id]).destroy
    end

    desc 'Delete multiple vehicle_usage_sets.',
      nickname: 'deleteVehicleUsageSets'
    params do
      requires :ids, type: Array[Integer], coerce_with: CoerceArrayInteger
    end
    delete do
      VehicleUsageSet.transaction do
        current_customer.vehicle_usage_sets.select{ |vehicle_usage_set| params[:ids].include?(vehicle_usage_set.id) }.each(&:destroy)
      end
    end
  end
end
