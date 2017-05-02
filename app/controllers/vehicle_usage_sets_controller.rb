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
class VehicleUsageSetsController < ApplicationController
  include LinkBack

  load_and_authorize_resource
  before_action :set_vehicle_usage_set, only: [:show, :edit, :update, :destroy, :duplicate]

  def index
    @customer = current_user.customer
  end

  def show
  end

  def new
    @vehicle_usage_set = current_user.customer.vehicle_usage_sets.build
    @vehicle_usage_set.store_start = current_user.customer.stores[0]
    @vehicle_usage_set.store_stop = current_user.customer.stores[0]
  end

  def edit
  end

  def create
    p = vehicle_usage_set_params
    time_with_day_params(params, p, [:open, :close, :rest_start, :rest_stop])
    @vehicle_usage_set = current_user.customer.vehicle_usage_sets.build(p)

    respond_to do |format|
      if @vehicle_usage_set.save
        format.html { redirect_to vehicle_usage_sets_path, notice: t('activerecord.successful.messages.created', model: @vehicle_usage_set.class.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      p = vehicle_usage_set_params
      time_with_day_params(params, p, [:open, :close, :rest_start, :rest_stop])
      @vehicle_usage_set.assign_attributes(p)

      if @vehicle_usage_set.save
        format.html { redirect_to link_back || vehicle_usage_sets_path, notice: t('activerecord.successful.messages.updated', model: @vehicle_usage_set.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @vehicle_usage_set.destroy
        format.html { redirect_to vehicle_usage_sets_url }
      else
        flash[:error] = @vehicle_usage_set.errors.full_messages
        format.html { render action: 'index' }
      end
    end
  end

  def destroy_multiple
    VehicleUsageSet.transaction do
      if params['vehicle_usage_sets']
        ids = params['vehicle_usage_sets'].keys.collect{ |i| Integer(i) }
        current_user.customer.vehicle_usage_sets.select{ |v| ids.include?(v.id) }.each(&:destroy)
      end
      respond_to do |format|
        format.html { redirect_to vehicle_usage_sets_url }
      end
    end
  end

  def duplicate
    respond_to do |format|
      @vehicle_usage_set = @vehicle_usage_set.duplicate
      @vehicle_usage_set.save!
      format.html { redirect_to edit_vehicle_usage_set_path(@vehicle_usage_set), notice: t('activerecord.successful.messages.updated', model: @vehicle_usage_set.class.model_name.human) }
    end
  end

  private

  def time_with_day_params(params, local_params, times)
    times.each do |time|
      local_params[time] = ChronicDuration.parse("#{params[:vehicle_usage_set]["#{time}_day".to_sym]} days and #{local_params[time].tr(':', 'h')}min") unless params[:vehicle_usage_set]["#{time}_day".to_sym].to_s.empty? || local_params[time].to_s.empty?
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_vehicle_usage_set
    @vehicle_usage_set = current_user.customer.vehicle_usage_sets.find params[:id] || params[:vehicle_usage_set_id]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def vehicle_usage_set_params
    params.require(:vehicle_usage_set).permit(:name,
                                              :open,
                                              :close,
                                              :store_start_id,
                                              :store_stop_id,
                                              :rest_start,
                                              :rest_stop,
                                              :rest_duration,
                                              :store_rest_id,
                                              :service_time_start,
                                              :service_time_end)
  end
end
