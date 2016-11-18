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
require 'coerce'

class V01::Zonings < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def zoning_params
      p = ActionController::Parameters.new(params)
      p = p[:zoning] if p.key?(:zoning)
      if p[:zones]
        p[:zones_attributes] = p[:zones]
      end
      p.permit(:name, zones_attributes: [:id, :name, :polygon, :_destroy, :vehicle_id, :speed_multiplicator])
    end
  end

  resource :zonings do
    desc 'Fetch customer\'s zonings.',
      nickname: 'getZonings',
      is_array: true,
      entity: V01::Entities::Zoning
    params do
      optional :ids, type: Array[Integer], desc: 'Select returned zonings by id.', coerce_with: CoerceArrayInteger
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
      detail: 'Create a new empty zoning. Zones will can be created for this zoning thereafter.',
      nickname: 'createZoning',
      params: V01::Entities::Zoning.documentation.except(:id).deep_merge(
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
      zoning.update! zoning_params
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
      requires :ids, type: Array[Integer], coerce_with: CoerceArrayInteger
    end
    delete do
      Zoning.transaction do
        current_customer.zonings.select{ |zoning| params[:ids].include?(zoning.id) }.each(&:destroy)
      end
    end

    desc 'Generate zoning from planning.',
      detail: 'Create new automatic zones in current zoning for a dedicated planning. Only stops in a route with vehicle are taken into account. All previous existing zones are cleared. Each generated zone is linked to a dedicated vehicle.',
      nickname: 'generateFromPlanning',
      entity: V01::Entities::Zoning
    params do
      requires :id, type: Integer
      requires :planning_id, type: Integer
    end
    patch ':id/from_planning/:planning_id' do
      Zoning.transaction do
        zoning = current_customer.zonings.find(params[:id])
        planning = current_customer.plannings.find(params[:planning_id])
        if zoning && planning
          zoning.from_planning(planning)
          zoning.save!
          present zoning, with: V01::Entities::Zoning
        end
      end
    end

    desc 'Generate zoning automatically.',
      detail: 'Create #N new automatic zones in current zoning for a dedicated planning (#N should be less or egal your vehicle\'s fleet size). All planning\'s stops (or all visits from destinations if there is no planning linked to this zoning) are taken into account, even if they are out of route. All previous existing zones are cleared. Each generated zone is linked to a dedicated vehicle.',
      nickname: 'generateAutomatic',
      entity: V01::Entities::Zoning
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

    desc 'Generate isochrones.',
      detail: 'Generate zoning with isochrone polygons for all vehicles. All previous existing zones are cleared.',
      nickname: 'generateIsochrone',
      entity: V01::Entities::Zoning
    params do
      requires :id, type: Integer
      requires :size, type: Integer, desc: 'Area accessible from the start store by this travel time in seconds.'
      optional :vehicle_usage_set_id, type: Integer, desc: 'If not provided, use one or the only one vehicle_usage_set.'
    end
    patch ':id/isochrone' do
      Zoning.transaction do
        zoning = current_customer.zonings.where(id: params[:id]).first
        vehicle_usage_set = if params.key?(:vehicle_usage_set_id)
          vehicle_usage_set_id = Integer(params[:vehicle_usage_set_id])
          current_customer.vehicle_usage_sets.to_a.find{ |vehicle_usage_set| vehicle_usage_set.id == vehicle_usage_set_id }
        else
          current_customer.vehicle_usage_sets[0]
        end
        size = Integer(params[:size])
        if zoning && vehicle_usage_set
          zoning.isochrones(size, vehicle_usage_set)
          zoning.save!
          present zoning, with: V01::Entities::Zoning
        else
          error! 'Zoning or VehicleUsageSet not found', 404
        end
      end
    end

    desc 'Generate isochrone for only one vehicle usage.',
      detail: 'Generate zoning with isochrone polygon from specified vehicle\'s start.',
      nickname: 'generateIsochroneVehicleUsage',
      entity: V01::Entities::Zone
    params do
      requires :id, type: Integer
      requires :size, type: Integer, desc: 'Area accessible from the start store by this travel time in seconds.'
      requires :vehicle_usage_id, type: Integer
    end
    patch ':id/vehicle_usage/:vehicle_usage_id/isochrone' do
      Zoning.transaction do
        zoning = current_customer.zonings.where(id: params[:id]).first
        vehicle_usage_id = Integer(params[:vehicle_usage_id])
        vehicle_usage = current_customer.vehicle_usage_sets.collect{ |vehicle_usage_set|
          vehicle_usage_set.vehicle_usages.find{ |vehicle_usage|
            vehicle_usage.id == vehicle_usage_id
          }
        }.compact.first
        size = Integer(params[:size])
        if zoning && vehicle_usage
          zoning.isochrone(size, vehicle_usage)
          zoning.save!
          present zoning.zones.find{ |z| z.vehicle == vehicle_usage.vehicle }, with: V01::Entities::Zone
        else
          error! 'Zoning or VehicleUsage not found', 404
        end
      end
    end

    desc 'Generate isodistances.',
      detail: 'Generate zoning with isodistance polygons for all vehicles. All previous existing zones are cleared.',
      nickname: 'generateIsodistance',
      entity: V01::Entities::Zoning
    params do
      requires :id, type: Integer
      requires :size, type: Integer, desc: 'Area accessible from the start store by this travel distance in meters.'
      optional :vehicle_usage_set_id, type: Integer, desc: 'If not provided, use one or the only one vehicle_usage_set.'
    end
    patch ':id/isodistance' do
      Zoning.transaction do
        zoning = current_customer.zonings.where(id: params[:id]).first
        vehicle_usage_set = if params.key?(:vehicle_usage_set_id)
          vehicle_usage_set_id = Integer(params[:vehicle_usage_set_id])
          current_customer.vehicle_usage_sets.to_a.find{ |vehicle_usage_set| vehicle_usage_set.id == vehicle_usage_set_id }
        else
          current_customer.vehicle_usage_sets[0]
        end
        size = Integer(params[:size])
        if zoning && vehicle_usage_set
          zoning.isodistances(size, vehicle_usage_set)
          zoning.save!
          present zoning, with: V01::Entities::Zoning
        else
          error! 'Zoning or VehicleUsageSet not found', 404
        end
      end
    end

    desc 'Generate isodistance for only one vehicle usage.',
      detail: 'Generate zoning with isodistance polygon from specified vehicle\'s start.',
      nickname: 'generateIsochroneVehicleUsage',
      entity: V01::Entities::Zone
    params do
      requires :id, type: Integer
      requires :size, type: Integer, desc: 'Area accessible from the start store by this travel distance in meters.'
      requires :vehicle_usage_id, type: Integer
    end
    patch ':id/vehicle_usage/:vehicle_usage_id/isodistance' do
      Zoning.transaction do
        zoning = current_customer.zonings.where(id: params[:id]).first
        vehicle_usage_id = Integer(params[:vehicle_usage_id])
        vehicle_usage = current_customer.vehicle_usage_sets.collect{ |vehicle_usage_set|
          vehicle_usage_set.vehicle_usages.find{ |vehicle_usage|
            vehicle_usage.id == vehicle_usage_id
          }
        }.compact.first
        size = Integer(params[:size])
        if zoning && vehicle_usage
          zoning.isodistance(size, vehicle_usage)
          zoning.save!
          present zoning.zones.find{ |z| z.vehicle == vehicle_usage.vehicle }, with: V01::Entities::Zone
        else
          error! 'Zoning or VehicleUsage not found', 404
        end
      end
    end

    desc 'Build isochrone for a point.',
      detail: 'Build isochrone polygon from a specific point. No zoning is saved in database.',
      nickname: 'buildIsochrone',
      entity: V01::Entities::Zoning
    params do
      requires :lat, type: Float, desc: 'Latitude.'
      requires :lng, type: Float, desc: 'Longitude.'
      requires :size, type: Integer, desc: 'Area accessible from the start point by this travel time in seconds.'
      optional :vehicle_usage_id, type: Integer, desc: 'If not provided, use default router from customer.'
    end
    patch 'isochrone' do
      zoning = Zoning.new customer_id: current_customer.id
      vehicle_usage = current_customer.vehicle_usage_sets.collect{ |vehicle_usage_set|
        vehicle_usage_set.vehicle_usages.find{ |vehicle_usage|
          vehicle_usage.id == params[:vehicle_usage_id]
        }
      }.compact.first
      size = Integer(params[:size])
      zoning.isochrone(size, vehicle_usage, [params[:lat], params[:lng]])
      present zoning, with: V01::Entities::Zoning
    end

    desc 'Build isodistance for a point.',
      detail: 'Build isodistance polygon from a specific point. No zoning is saved in database.',
      nickname: 'buildIsodistance',
      entity: V01::Entities::Zoning
    params do
      requires :lat, type: Float, desc: 'Latitude.'
      requires :lng, type: Float, desc: 'Longitude.'
      requires :size, type: Integer, desc: 'Area accessible from the start point by this travel distance in meters.'
      optional :vehicle_usage_id, type: Integer, desc: 'If not provided, use default router from customer.'
    end
    patch 'isodistance' do
      zoning = Zoning.new customer_id: current_customer.id
      vehicle_usage = current_customer.vehicle_usage_sets.collect{ |vehicle_usage_set|
        vehicle_usage_set.vehicle_usages.find{ |vehicle_usage|
          vehicle_usage.id == params[:vehicle_usage_id]
        }
      }.compact.first
      size = Integer(params[:size])
      zoning.isodistance(size, vehicle_usage, [params[:lat], params[:lng]])
      present zoning, with: V01::Entities::Zoning
    end

  end
end
