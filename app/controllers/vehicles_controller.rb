# Copyright © Mapotempo, 2013-2014
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
class VehiclesController < ApplicationController
  include LinkBack

  load_and_authorize_resource except: :create
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]

  def index
    @vehicles = current_user.customer.vehicles
  end

  def new
    @vehicle = current_user.customer.vehicles.build
  end

  def edit
  end

  def create
    @vehicle = current_user.customer.vehicles.build(vehicle_params)

    respond_to do |format|
      if @vehicle.save
        format.html { redirect_to vehicles_path, notice: t('activerecord.successful.messages.created', model: @vehicle.class.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @vehicle.update(vehicle_params)
        format.html { redirect_to link_back || vehicles_path, notice: t('activerecord.successful.messages.updated', model: @vehicle.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @vehicle.destroy
    respond_to do |format|
      format.html { redirect_to vehicles_url }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def vehicle_params
    params.require(:vehicle).permit(:name, :emission, :consumption, :capacity, :color, :open, :close, :tomtom_id, :masternaut_ref, :store_start_id, :store_stop_id, :router_id)
  end
end
