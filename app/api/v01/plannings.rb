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
      p[:zoning_ids] = [p[:zoning_id]] if p[:zoning_id] && (!p[:zoning_ids] || p[:zoning_ids].empty?)
      p.permit(:name, :ref, :date, :vehicle_usage_set_id, tag_ids: [], zoning_ids: [])
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'.freeze
  end

  resource :plannings do
    desc 'Create planning.',
      detail: 'Create a planning. An out-of-route (unplanned) route and a route for each vehicle are automatically created. If some visits exist (or fetch if you use tags), as many stops as fetching visits will be created.',
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
      planning.update! planning_params
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

    desc 'Recompute the planning after parameter update.',
      detail: 'Refresh planning and out_of_date routes infos if inputs have been changed (for instance stores, destinations, visits, etc...)',
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

    desc 'Insert one or more stop into planning routes',
      detail: 'Insert automaticaly one or more stops in best routes and on best positions to have minimal influence on route\'s total time (this operation doesn\'t take into account time windows if they exist...). You should use this operation with existing stops in current planning\'s routes. In addition, you should not use this operation with many stops. You should use instead zoning (with automatic clustering creation for instance) to set multiple stops in each available route.',
      nickname: 'automaticInsertStop'
    params do
      requires :id, type: String, desc: ID_DESC
      requires :stop_ids, type: Array[Integer], desc: 'Ids separated by comma. You should not have many stops.', documentation: { param_type: 'form' }, coerce_with: CoerceArrayInteger
    end
    patch ':id/automatic_insert' do
      planning_id = ParseIdsRefs.read params[:id]
      planning = current_customer.plannings.where(planning_id).first!
      stops = Stop.where id: params[:stop_ids], route_id: planning.route_ids
      error!('Not Found', 404) if stops.empty?
      stops.each{ |stop| planning.automatic_insert(stop) }
      planning.save!
      status 200
    end

    desc 'Optimize routes',
      detail: 'Optimize all unlocked routes by keeping visits in same route or not.',
      nickname: 'optimizeRoutes'
    params do
      requires :id, type: String, desc: ID_DESC
      optional :global, type: Boolean, desc: 'Use global optimization and move visits between routes if needed', default: false
      optional :details, type: Boolean, desc: 'Output route details', default: false
      optional :synchronous, type: Boolean, desc: 'Synchronous', default: true
    end
    get ':id/optimize' do
      id = ParseIdsRefs.read params[:id]
      planning = current_customer.plannings.where(id).first!
      Optimizer.optimize planning, nil, params[:global], params[:synchronous]
      if params[:details]
        present planning, with: V01::Entities::Planning
      else
        status 204
      end
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
      planning = planning.duplicate
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Use order_array in the planning.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'useOrderArray',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
      requires :order_array_id, type: Integer
      requires :shift, type: Integer
    end
    patch ':id/order_array' do
      id = ParseIdsRefs.read(params[:id])
      planning = current_customer.plannings.where(id).first!
      order_array = current_customer.order_arrays.find(params[:order_array_id])
      shift = Integer(params[:shift])
      planning.apply_orders(order_array, shift)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Update Routes'
    params do
      requires :id, type: String, desc: ID_DESC
      requires :route_ids, type: Array[Integer], documentation: { param_type: 'form' }, coerce_with: CoerceArrayInteger, desc: 'Ids separated by comma.'
      requires :selection, type: String, values: %w(all reverse none)
      requires :action, type: String, values: %w(toggle lock)
    end
    patch ':id/update_routes' do
      planning_id = ParseIdsRefs.read params[:id]
      planning = current_customer.plannings.where(planning_id).first!
      routes = planning.routes.find params[:route_ids]
      routes.each do |route|
        case params[:action].to_sym
        when :toggle
          case params[:selection].to_sym
          when :all
            route.update! hidden: false
          when :reverse
            route.update! hidden: !route.hidden
          when :none
            route.update! hidden: true
          end
        when :lock
          case params[:selection].to_sym
          when :all
            route.update! locked: true
          when :reverse
            route.update! locked: !route.locked
          when :none
            route.update! locked: false
          end
        end
      end
      present routes, with: V01::Entities::Route
    end
  end
end
