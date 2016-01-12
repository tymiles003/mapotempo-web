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

class V01::Routes < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def route_params
      p = ActionController::Parameters.new(params)
      p = p[:route] if p.key?(:route)
      p.permit(:hidden, :locked, :ref, :color)
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :plannings do
    params do
      requires :planning_id, type: String, desc: ID_DESC
    end
    segment '/:planning_id' do

      resource :routes do
        desc 'Fetch planning\'s routes.',
          nickname: 'getRoutes',
          is_array: true,
          entity: V01::Entities::Route
        params do
          optional :ids, type: Array[String], desc: 'Select returned routes by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
        end
        get do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          routes = if params.key?(:ids)
            current_customer.plannings.where(planning_id).first!.routes.select{ |route|
              params[:ids].any?{ |s| ParseIdsRefs.match(s, route) }
            }
          else
            current_customer.plannings.where(planning_id).first!.routes.load
          end
          present routes, with: V01::Entities::Route
        end

        desc 'Fetch route.',
          nickname: 'getRoute',
          entity: V01::Entities::Route
        params do
          requires :id, type: String, desc: ID_DESC
        end
        get ':id' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          id = ParseIdsRefs.read(params[:id])
          present current_customer.plannings.where(planning_id).first!.routes.where(id).first!, with: V01::Entities::Route
        end

        desc 'Update route.',
          nickname: 'updateRoute',
          params: V01::Entities::Route.documentation.slice(:hidden, :locked, :color),
          entity: V01::Entities::Route
        params do
          requires :id, type: String, desc: ID_DESC
        end
        put ':id' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          id = ParseIdsRefs.read(params[:id])
          route = current_customer.plannings.where(planning_id).first!.routes.where(id).first!
          route.update(route_params)
          route.save!
          present route, with: V01::Entities::Route
        end

        desc 'Change stops activation.',
          detail: 'Allow to activate/deactivate a stop in a planning\'s route.',
          nickname: 'activationStops',
          entity: V01::Entities::Route
        params do
          requires :id, type: String, desc: ID_DESC
          requires :active, type: String, values: ['all', 'reverse', 'none']
        end
        patch ':id/active/:active' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          planning = current_customer.plannings.where(planning_id).first!
          id = ParseIdsRefs.read(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }
          if route && route.active(params[:active].to_s.to_sym) && route.compute && planning.save!
            present(route, with: V01::Entities::Route)
          end
        end

        desc 'Move visit to routes. Append in order at end.',
          detail: 'Set a new A route (or vehicle) for a visit which was in a previous B route in the same planning.',
          nickname: 'moveVisits'
        params do
          requires :id, type: String, desc: ID_DESC
          requires :visit_ids, type: Array[Integer], documentation: {param_type: 'form'}
        end
        patch ':id/visits/moves' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          planning = current_customer.plannings.find{ |planning| planning_id[:ref] ? planning.ref == planning_id[:ref] : planning.id == planning_id[:id] }
          id = ParseIdsRefs.read(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }
          ids = params[:visit_ids].collect{ |i| Integer(i) }
          visits = current_customer.visits.select{ |visit| ids.include?(visit.id) }

          if route && planning && visits
            Planning.transaction do
              visits.each{ |visit|
                route.move_visit(visit, -1)
              }
              planning.save!
            end

            status 204
          else
            status 400
          end
        end

        desc 'Starts asynchronous route optimization.',
          detail: 'Get the shortest route in time.',
          nickname: 'optimizeRoute'
        params do
          requires :id, type: String, desc: ID_DESC
        end
        patch ':id/optimize' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          id = ParseIdsRefs.read(params[:id])
          route = current_customer.plannings.where(planning_id).first!.routes.where(id).first!
          if !Optimizer.optimize(route.planning, route, true)
            status 304
          else
            route.planning.customer.save!
            status 204
          end
        end
      end
    end
  end
end
