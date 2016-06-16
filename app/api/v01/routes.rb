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
          route.update! route_params
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

        desc 'Move visit(s) to route. Append in order at end if automatic_insert is false.',
          detail: 'Set a new A route (or vehicle) for a visit which was in a previous B route in the same planning. Automatic_insert parameter allows to compute index of the stops created for visits.',
          nickname: 'moveVisits'
        params do
          requires :id, type: String, desc: ID_DESC
          requires :visit_ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', documentation: {param_type: 'form'}, coerce_with: CoerceArrayString
          optional :automatic_insert, type: Boolean, desc: 'If true, the best index in the route is automatically computed to have minimum impact on total route distance (without taking into account constraints like open/close, you have to start a new optimization if needed).'
        end
        patch ':id/visits/moves' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          planning = current_customer.plannings.find{ |planning| planning_id[:ref] ? planning.ref == planning_id[:ref] : planning.id == planning_id[:id] }
          id = ParseIdsRefs.read(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }
          visits = current_customer.visits.select{ |visit| params[:visit_ids].any?{ |s| ParseIdsRefs.match(s, visit) } }
          visits_ordered = []
          params[:visit_ids].each{ |s| visits_ordered << visits.find{ |visit| ParseIdsRefs.match(s, visit) } }

          if route && planning && visits_ordered.size > 0
            Planning.transaction do
              visits_ordered.each{ |visit|
                planning.move_visit(route, visit, params[:automatic_insert] ? nil : -1)
              }
              planning.save!
            end

            status 204
          else
            status 400
          end
        end

        desc 'Starts synchronous route optimization.',
          detail: 'Get the shortest route in time.',
          nickname: 'optimizeRoute'
        params do
          requires :id, type: String, desc: ID_DESC
          optional :details, type: Boolean, desc: 'Output Route Details', default: false
          optional :synchronous, type: Boolean, desc: 'Synchronous', default: true
        end
        patch ':id/optimize' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          route = current_customer.plannings.where(planning_id).first!.routes.find{ |r| ParseIdsRefs.match(params[:id], r) }
          if !Optimizer.optimize(route.planning, route, params[:synchronous])
            status 304
          else
            route.planning.customer.save!
            if params[:details]
              present route, with: V01::Entities::Route
            else
              status 204
            end
          end
        end
      end

      resource :routes_by_vehicle do
        desc 'Fetch route from vehicle.',
          nickname: 'getRouteByVehicle',
          entity: V01::Entities::Route
        params do
          requires :planning_id, type: String, desc: ID_DESC
          requires :id, type: String, desc: 'ID / Ref (ref:abcd) of the VEHICLE attached to the Route'
        end
        get ':id' do
          planning_id = ParseIdsRefs.read params[:planning_id] rescue error!('Invalid IDs', 400)
          vehicle_id = ParseIdsRefs.read params[:id] rescue error!('Invalid IDs', 400)
          planning = current_customer.plannings.find_by planning_id
          error!('Not Found', 404) if !planning
          route = planning.routes.detect{ |route| route.vehicle_usage && ParseIdsRefs.match(params[:id], route.vehicle_usage.vehicle) }
          error!('Not Found', 404) if !route
          present route, with: V01::Entities::Route
        end
      end
    end
  end
end
