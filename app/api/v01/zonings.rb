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
class V01::Zonings < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def zoning_params
      p = ActionController::Parameters.new(params)
      p = p[:zoning] if p.key?(:zoning)
      if p[:zones]
        p[:zones_attributes] = p[:zones]
      end
      p.permit(:name, zones_attributes: [:id, :polygon, :_destroy, :vehicle_id])
    end
  end

  resource :zonings do
    desc 'Fetch customer\'s zonings.',
      nickname: 'getZonings',
      is_array: true,
      entity: V01::Entities::Zoning
    params do
      optional :ids, type: Array[Integer], desc: 'Select returned zonings by id.', coerce_with: V01::CoerceArrayInteger
    end
    get do
      zonings = if params.key?(:ids)
        current_customer.zonings.select{ |zoning| params[:ids].include?(zoning.id) }
      else
        current_customer.zonings.load
      end
      present zonings, with: V01::Entities::Zoning
    end

    desc 'Fetch zoning.',
      nickname: 'getZoning',
      entity: V01::Entities::Zoning
    params do
      requires :id, type: Integer
    end
    get ':id' do
      present current_customer.zonings.find(params[:id]), with: V01::Entities::Zoning
    end

    desc 'Create zoning.',
      nickname: 'createZoning',
      params: V01::Entities::Zoning.documentation.except(:id).merge(
        name: { required: true }
      ),
      entity: V01::Entities::Zoning
    post do
      zoning = current_customer.zonings.build(zoning_params)
      zoning.save!
      present zoning, with: V01::Entities::Zoning
    end

    desc 'Update zoning.',
      nickname: 'updateZoning',
      params: V01::Entities::Zoning.documentation.except(:id),
      entity: V01::Entities::Zoning
    params do
      requires :id, type: Integer
    end
    put ':id' do
      zoning = current_customer.zonings.find(params[:id])
      zoning.update(zoning_params)
      zoning.save!
      present zoning, with: V01::Entities::Zoning
    end

    desc 'Delete zoning.',
      nickname: 'deleteZoning'
    params do
      requires :id, type: Integer
    end
    delete ':id' do
      current_customer.zonings.find(params[:id]).destroy
    end

    desc 'Delete multiple zonings.',
      nickname: 'deleteZonings'
    params do
      requires :ids, type: Array[Integer]
    end
    delete do
      Zoning.transaction do
        ids = params[:ids].collect{ |i| Integer(i) }
        current_customer.zonings.select{ |zoning| ids.include?(zoning.id) }.each(&:destroy)
      end
    end

    desc 'Generate zoning from planning.',
      nickname: 'generateFromPlanning'
    params do
      requires :id, type: Integer
      requires :planning_id, type: Integer
    end
    patch ':id/from_planning/:planning_id' do
      Zoning.transaction do
        zoning = current_customer.zonings.find(params[:id])
        planning = current_customer.plannings.find(params[:planning_id])
        n = params.key?(:n) ? Integer(params[:n]) : nil
        if zoning && planning
          zoning.from_planning(planning)
          zoning.save!
          present zoning, with: V01::Entities::Zoning
        end
      end
    end

    desc 'Generate zoning automatically.',
      nickname: 'generateAutomatic'
    params do
      requires :id, type: Integer
      requires :planning_id, type: Integer
      optional :n, type: Integer, desc: 'Number of produced zones. Default to vehicles number.'
    end
    patch ':id/automatic/:planning_id' do
      Zoning.transaction do
        zoning = current_customer.zonings.find(params[:id])
        planning = current_customer.plannings.find(params[:planning_id])
        n = params.key?(:n) ? Integer(params[:n]) : nil
        if zoning && planning
          zoning.automatic_clustering(planning, n)
          zoning.save!
          present zoning, with: V01::Entities::Zoning
        end
      end
    end

    desc 'Generate isochrone.',
      nickname: 'generateIsochrone'
    params do
      requires :id, type: Integer
      requires :size, type: Integer, desc: 'Area accessible from the start store by this travel time.'
    end
    patch ':id/isochrone' do
      Zoning.transaction do
        zoning = current_customer.zonings.find(params[:id])
        size = Integer(params[:size])
        if zoning
          zoning.isochrone(size)
          zoning.save!
          present zoning, with: V01::Entities::Zoning
        end
      end
    end
  end
end
