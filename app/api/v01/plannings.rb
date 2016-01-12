# Copyright © Mapotempo, 2014-2016
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

class V01::Plannings < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def planning_params
      p = ActionController::Parameters.new(params)
      p = p[:planning] if p.key?(:planning)
      p.permit(:name, :ref, :date, :vehicle_usage_set_id, :zoning_id, tag_ids: [])
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :plannings do
    desc 'Fetch customer\'s plannings.',
      nickname: 'getPlannings',
      is_array: true,
      entity: V01::Entities::Planning
    params do
      optional :ids, type: Array[String], desc: 'Select returned plannings by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    get do
      plannings = if params.key?(:ids)
        current_customer.plannings.select{ |planning|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, planning) }
        }
      else
        current_customer.plannings.load
      end
      present plannings, with: V01::Entities::Planning
    end

    desc 'Fetch planning.',
      nickname: 'getPlanning',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read(params[:id])
      present current_customer.plannings.where(id).first!, with: V01::Entities::Planning
    end

    desc 'Create planning.',
      nickname: 'createPlanning',
      params: V01::Entities::Planning.documentation.except(:id, :route_ids, :out_of_date, :tag_ids).deep_merge(
        name: { required: true },
        vehicle_usage_set_id: { required: true }
      ),
      entity: V01::Entities::Planning
    params do
      optional :tag_ids, type: Array[Integer], desc: 'Ids separated by comma.', coerce_with: CoerceArrayInteger, documentation: { param_type: 'form' }
    end
    post do
      planning = current_customer.plannings.build(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Update planning.',
      nickname: 'updatePlanning',
      params: V01::Entities::Planning.documentation.except(:id, :route_ids, :out_of_date, :tags_ids),
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    put ':id' do
      id = ParseIdsRefs.read(params[:id])
      planning = current_customer.plannings.where(id).first!
      planning.update(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Delete planning.',
      nickname: 'deletePlanning'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    delete ':id' do
      id = ParseIdsRefs.read(params[:id])
      current_customer.plannings.where(id).first!.destroy
    end

    desc 'Delete multiple plannings.',
      nickname: 'deletePlannings'
    params do
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    delete do
      Planning.transaction do
        current_customer.plannings.select{ |planning|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, planning) }
        }.each(&:destroy)
      end
    end

    desc 'Force recompute the planning after parameter update.',
      detail: 'Refresh planning and routes infos if inputs have been changed (for instance stores, destinations, visits, etc...)',
      nickname: 'refreshPlanning',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id/refresh' do
      id = ParseIdsRefs.read(params[:id])
      planning = current_customer.plannings.where(id).first!
      planning.compute
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Switch two vehicles.',
      detail: 'Not Implemented',
      nickname: 'switchVehicles'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    patch ':id/switch' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Suggest a place for an unaffected stop.',
      detail: 'Not Implemented',
      nickname: 'automaticInsertStop'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    patch ':id/automatic_insert' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Starts asynchronous routes optimization.',
      detail: 'Not Implemented',
      nickname: 'optimizeRoutes'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id/optimize_each_routes' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Clone the planning.',
      nickname: 'clonePlanning',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    patch ':id/duplicate' do
      id = ParseIdsRefs.read(params[:id])
      planning = current_customer.plannings.where(id).first!
      planning = planning.amoeba_dup
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Use order_array in the planning.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'useOrderArray',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
      requires :order_array_id, type: String
      requires :shift, type: Integer
    end
    patch ':id/orders/:order_array_id/:shift' do
      id = ParseIdsRefs.read(params[:id])
      planning = current_customer.plannings.where(id).first!
      order_array = current_customer.order_arrays.find(params[:order_array_id])
      shift = Integer(params[:shift])
      planning.apply_orders(order_array, shift)
      planning.save!
      present planning, with: V01::Entities::Planning
    end
  end
end
