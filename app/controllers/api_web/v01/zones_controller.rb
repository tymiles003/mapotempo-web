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
class ApiWeb::V01::ZonesController < ApiWeb::V01::ApiWebController
  load_and_authorize_resource :zoning
  load_and_authorize_resource :zone, through: :zoning
  before_action :set_zoning, only: [:index]
  before_action :set_zone, only: []

  swagger_controller :zones, 'Zones'

  swagger_api :index do
    summary 'Display all or some zones of one zoning.'
    param :path, :zoning_id, :integer, :required, 'Zonning ids'
    param :query, :ids, :array, :optional, 'Zoning''s zones ids to be displayed, separated by commas', { 'items' => { 'type' => 'integer' } }
    param :query, :destinations, :boolean, :optional, 'Destinations displayed or not, no destinations by default'
  end

  def index
    @zones = if params.key?(:ids)
      ids = params[:ids].split(',')
      @zoning.zones.select{ |zone| ids.include?(zone.id.to_s) }
    else
      @zoning.zones
    end
    if params[:destinations]
      @destinations = current_user.customer.destinations
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # rights should be checked before thanks to CanCan::Ability
  def set_zoning
    @zoning = Zoning.find(params[:zoning_id])
  end

  def set_zone
    @zone = Zone.find(params[:id] || params[:zone_id])
  end
end
