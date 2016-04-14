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
class ApiWeb::V01::RoutesController < ApiWeb::V01::ApiWebController
  load_and_authorize_resource :planning
  load_and_authorize_resource :route, through: :planning
  before_action :set_planning, only: [:index]
  before_action :set_route, only: []

  swagger_controller :routes, 'Routes'

  swagger_api :index do
    summary 'Display all or some routes of one planning.'
    param :path, :planning_id, :integer, :required, 'Zonning ids'
    param :query, :ids, :array, :optional, 'Planning''s routes ids or refs (as "ref:[VALUE]") to be displayed, separated by commas', { 'items' => { 'type' => 'string' } }
  end

  def index
    @routes = if params.key?(:ids)
      ids = params[:ids].split(',')
      @planning.routes.where(ParseIdsRefs.where(Route, ids))
    else
      @planning.routes
    end
    @layer = current_user.customer.profile.layers.find_by(id: params[:layer_id]) if params[:layer_id]
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # rights should be checked before thanks to CanCan::Ability
  def set_planning
    @planning = Planning.find(params[:planning_id])
  end

  def set_route
    @route = Route.find(params[:id] || params[:route_id])
  end
end
