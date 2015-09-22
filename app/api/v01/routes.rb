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
          optional :ids, type: Array[Integer], desc: 'Select returned routes by id.', coerce_with: V01::CoerceArrayInteger
        end
        get do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          routes = if params.key?(:ids)
            current_customer.plannings.where(planning_id).first!.routes.select{ |route| params[:ids].include?(route.id) }
          else
            current_customer.plannings.where(planning_id).first!.routes.load
          end
          present routes, with: V01::Entities::Route
        end

        desc 'Fetch route.',
          nickname: 'getRoute',
          entity: V01::Entities::Route
        params do
          requires :id, type: Integer
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
          requires :id, type: Integer
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
          nickname: 'activationStops',
          entity: V01::Entities::Route
        params do
          requires :id, type: Integer
          requires :active, type: String, values: ['all', 'reverse', 'none']
        end
        patch ':id/active/:active' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          planning = current_customer.plannings.where(planning_id).first!
          id = ParseIdsRefs.read(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }
          if route && route.active(params[:active].to_s.to_sym) && route.compute && planning.save
            present(route, with: V01::Entities::Route)
          end
        end

        desc 'Move destination to routes. Append in order at end.',
          nickname: 'moveDestinations'
        params do
          requires :id, type: String
          requires :destination_ids, type: Array[Integer]
        end
        patch ':id/destinations/moves' do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          planning = current_customer.plannings.find{ |planning| planning_id[:ref] ? planning.ref == planning_id[:ref] : planning.id == planning_id[:id] }
          id = ParseIdsRefs.read(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }


          ids = params[:destination_ids].collect{ |i| Integer(i) }
          destinations = current_customer.destinations.select{ |destination| ids.include?(destination.id) }

          Planning.transaction do
            destinations.each{ |destination|
              route.move_destination(destination, route.stops.size)
            }
            planning.save
          end
        end

        desc 'Starts asynchronous route optimization.',
          nickname: 'optimizeRoute'
        params do
          requires :id, type: Integer
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
