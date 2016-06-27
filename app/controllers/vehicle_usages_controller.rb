# Copyright © Mapotempo, 2015-2016
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
class VehicleUsagesController < ApplicationController
  include LinkBack

  load_and_authorize_resource
  before_action :set_vehicle_usage, only: [:show, :edit, :update, :destroy, :toggle]

  def edit
  end

  def update
    respond_to do |format|
      @vehicle_usage.assign_attributes(vehicle_usage_params)
      if @vehicle_usage.save
        format.html { redirect_to link_back || edit_vehicle_usage_path(@vehicle_usage), notice: t('activerecord.successful.messages.updated', model: @vehicle_usage.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def toggle
    if @vehicle_usage.update active: !@vehicle_usage.active?
      redirect_to link_back || vehicle_usage_sets_path, notice: t('.success')
    else
      render action: :edit
    end
  end

  private

  def set_vehicle_usage
    @vehicle_usage = VehicleUsage.for_customer(current_user.customer).find params[:id]
  end

  def vehicle_usage_params
    if params[:vehicle_usage][:vehicle][:router]
      params[:vehicle_usage][:vehicle][:router_id], params[:vehicle_usage][:vehicle][:router_dimension] = params[:vehicle_usage][:vehicle][:router].split('_')
    end
    p = params.require(:vehicle_usage).permit(:open, :close, :store_start_id, :store_stop_id, :rest_start, :rest_stop, :rest_duration, :store_rest_id, :service_time_start, :service_time_end, vehicle: [:contact_email, :ref, :name, :emission, :consumption, :capacity, :capacity_unit, :color, :tomtom_id, :teksat_id, :orange_id, :masternaut_ref, :router_id, :router_dimension, :speed_multiplicator])
    if p.key?(:vehicle)
      p[:vehicle_attributes] = p[:vehicle]
      p.except(:vehicle)
    end
  end
end
