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
class ApiWeb::V01::DestinationsController < ApiWeb::V01::ApiWebController
  load_and_authorize_resource
  before_action :set_destination, only: [:edit_position, :update_position]

  swagger_controller :stores, 'Destinations'

  swagger_api :index do
    summary 'Display all or some destinations.'
    param :query, :ids, :array, :optional, 'Destination ids or refs (as "ref:[VALUE]") to be displayed, separated by commas', { 'items' => { 'type' => 'string' } }
  end

  swagger_api :edit_position do
    summary 'Display a movable position marker of the destination.'
    param :path, :id, :integer, :required
  end

  swagger_api :update_position, method: :patch do
    summary 'Save the destination position.'
    param :path, :id, :integer, :required
    param :query, :lat, :float, :optional
    param :query, :lng, :float, :optional
  end

  def index
    @customer = current_user.customer
    @destinations = if params.key?(:ids)
      ids = params[:ids].split(',')
      current_user.customer.destinations.where(ParseIdsRefs.where(Destination, ids))
    else
      respond_to do |format|
        format.html do
          nil
        end
        format.json do
          current_user.customer.destinations.load
        end
      end
    end
    @tags = current_user.customer.tags
  end

  def edit_position
  end

  def update_position
    respond_to do |format|
      begin
        Destination.transaction do
          @destination.update(destination_params)
          @destination.save!
          @destination.customer.save!
          format.html { redirect_to api_web_v01_edit_position_destination_path(@destination), notice: t('activerecord.successful.messages.updated', model: @destination.class.model_name.human) }
        end
      rescue => e
        flash.now[:error] = e.message
        format.html { render action: 'edit_position' }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_destination
    @destination = Destination.find(params[:id] || params[:destination_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def destination_params
    params.require(:destination).permit(:ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :take_over, :open, :close, :comment, :phone_number, tag_ids: [])
  end
end
