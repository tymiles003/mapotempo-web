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
class V01::Stops < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def stop_params
      p = ActionController::Parameters.new(params)
      p.permit(:active)
    end
  end

  resource :plannings do
    params do
      requires :planning_id, type: Integer
    end
    segment '/:planning_id' do

      resource :routes do
        params do
          requires :route_id, type: Integer
        end
        segment '/:route_id' do

          resource :stops do
            desc 'Update stop.',
              nickname: 'updateStop',
              params: V01::Entities::Stop.documentation.slice(:active)
            params do
              requires :id, type: Integer
            end
            put ':id' do
              planning_id = Integer(params[:planning_id])
              route_id = Integer(params[:route_id])
              id = Integer(params[:id])
              planning = current_customer.plannings.find{ |planning| planning.id == planning_id }
              route = planning.routes.find{ |route| route.id == route_id }
              stop = route.stops.find{ |stop| stop.id == id }
              stop.update! stop_params
              route.compute && planning.save!
              status 204
            end

            desc 'Move stop position in routes.',
              detail: 'Set a new #N position for a stop in route which was in a previous #M position in the same route.',
              nickname: 'moveStop'
            params do
              requires :id, type: Integer, desc: 'Stop id to move'
              requires :index, type: Integer, desc: 'New position in the route'
            end
            patch ':id/move/:index' do
              planning_id = Integer(params[:planning_id])
              route_id = Integer(params[:route_id])
              stop_id = Integer(params[:id])
              planning = current_customer.plannings.find{ |planning| planning.id == planning_id }
              route = planning.routes.find{ |route| route.id == route_id }
              stop = nil
              planning.routes.find{ |route| stop = route.stops.find{ |stop| stop.id == stop_id } }

              route.move_stop(stop, Integer(params[:index]) + 1) && planning.save!
              status 204
            end
          end
        end
      end
    end
  end
end
