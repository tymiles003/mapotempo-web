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
  load_and_authorize_resource
  before_action :set_planning, only: [:index]
  before_action :set_route, only: []

  swagger_controller :routes, 'Routes'

  swagger_api :index do
    summary 'Display all or some routes of one planning.'
    param :path, :planning_id, :integer, :required, 'Zonning ids'
    param :query, :ids, :array, :optional, 'Planning''s routes ids to be displayed', { 'items' => { 'type' => 'integer' } }
  end

  def index
    @routes = if params.key?(:ids) && params[:ids].kind_of?(Array)
      ids = params[:ids].collect(&:to_i)
      @planning.routes.select{ |route| ids.include?(route.id) }
    else
      routes = @planning.routes
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_planning
    @planning = Planning.find(params[:planning_id])
  end

  def set_route
    @route = Route.find(params[:id] || params[:route_id])
  end
end
