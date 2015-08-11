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
class ApiWeb::DestinationsController < ApplicationController
  load_and_authorize_resource
  before_action :set_destination, only: [:edit_position, :update_position]
  layout 'api_web'

  def index
    @customer = current_user.customer
    @destinations = if params.key?(:ids) && params[:ids].kind_of?(Array)
      ids = params[:ids].collect(&:to_i)
      current_user.customer.destinations.select{ |destination| ids.include?(destination.id) }
    else
      current_user.customer.destinations.load
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
          format.html { redirect_to api_web_edit_position_destination_path(@destination), notice: t('activerecord.successful.messages.updated', model: @destination.class.model_name.human) }
        end
      rescue => e
        flash[:error] = e.message
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
    params.require(:destination).permit(:ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :take_over, :open, :close, :comment, tag_ids: [])
  end
end
