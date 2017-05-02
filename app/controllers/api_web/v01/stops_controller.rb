# Copyright © Mapotempo, 2017
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

class ApiWeb::V01::StopsController < ApiWeb::V01::ApiWebController
  skip_before_filter :verify_authenticity_token # because rails waits for a form token with POST
  load_and_authorize_resource

  swagger_controller :stops, 'Stops'

  swagger_api :show do
    summary 'Show a stops details.'
    param :path, :stop_id, :integer, :required, 'Stop id'
  end

  def show
    respond_to do |format|
      @manage_planning = []
      @show_isoline = false
      format.json
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def route_params
    params.require(:stop).permit
  end
end
