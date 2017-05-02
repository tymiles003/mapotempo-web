# Copyright © Mapotempo, 2016
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
class ApiWeb::V01::PlanningsController < ApiWeb::V01::ApiWebController
  skip_before_filter :verify_authenticity_token # because rails waits for a form token with POST
  load_and_authorize_resource
  before_action :manage_planning

  swagger_controller :plannings, 'Plannings'

  swagger_api :edit do
    summary 'Edit all or some routes of one planning.'
    param :path, :planning_id, :integer, :required, 'Zonning ids'
    param :query, :ids, :array, :optional, 'Planning''s routes ids or refs (as "ref:[VALUE]") to be displayed, separated by commas', 'items' => { 'type' => 'string' }
  end

  def edit
    @spreadsheet_columns = []
    capabilities
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # rights should be checked before thanks to CanCan::Ability
  def manage_planning
    @manage_planning = [:organize]
    @callback_button = true
  end

  def capabilities
    @isochrone = []
    @isodistance = []
  end
end
