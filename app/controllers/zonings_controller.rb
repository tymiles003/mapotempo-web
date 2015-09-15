# Copyright © Mapotempo, 2013-2015
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
class ZoningsController < ApplicationController
  include LinkBack

  load_and_authorize_resource
  before_action :set_zoning, only: [:show, :edit, :update, :destroy, :duplicate, :automatic, :from_planning, :isochrone]

  def index
    @zonings = current_user.customer.zonings
  end

  def show
  end

  def new
    @zoning = current_user.customer.zonings.build
    @planning = params.key?(:planning_id) ? current_user.customer.plannings.find(params[:planning_id]) : nil
  end

  def edit
    @planning = params.key?(:planning_id) ? current_user.customer.plannings.find(params[:planning_id]) : nil
  end

  def create
    @zoning = current_user.customer.zonings.build(zoning_params)

    respond_to do |format|
      if @zoning.save
        format.html { redirect_to edit_zoning_path(@zoning, planning_id: params.key?(:planning_id) ? params[:planning_id] : nil), notice: t('activerecord.successful.messages.created', model: @zoning.class.model_name.human) }
      else
        @planning = params.key?(:planning_id) ? current_user.customer.plannings.find(params[:planning_id]) : nil
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @zoning.update_attributes(zoning_params) && @zoning.save
        format.html { redirect_to link_back || edit_zoning_path(@zoning, planning_id: params.key?(:planning_id) ? params[:planning_id] : nil), notice: t('activerecord.successful.messages.updated', model: @zoning.class.model_name.human) }
      else
        @planning = params.key?(:planning_id) ? current_user.customer.plannings.find(params[:planning_id]) : nil
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @zoning.destroy
    respond_to do |format|
      format.html { redirect_to zonings_url }
    end
  end

  def destroy_multiple
    Zoning.transaction do
      if params['zonings']
        ids = params['zonings'].keys.collect{ |i| Integer(i) }
        current_user.customer.zonings.select{ |zoning| ids.include?(zoning.id) }.each(&:destroy)
      end
      respond_to do |format|
        format.html { redirect_to zonings_url }
      end
    end
  end

  def duplicate
    respond_to do |format|
      @zoning = @zoning.amoeba_dup
      @zoning.save!
      format.html { redirect_to edit_zoning_path(@zoning), notice: t('activerecord.successful.messages.updated', model: @zoning.class.model_name.human) }
    end
  end

  def automatic
    respond_to do |format|
      @planning = params.key?(:planning_id) ? current_user.customer.plannings.find(params[:planning_id]) : nil
      if @planning
        @zoning.automatic_clustering(@planning, params[:n] ? Integer(params[:n]) : nil)
        @zoning.save
      end
      format.json { render action: 'edit' }
    end
  end

  def from_planning
    respond_to do |format|
      @planning = params.key?(:planning_id) ? current_user.customer.plannings.find(params[:planning_id]) : nil
      if @planning
        @zoning.from_planning(@planning)
        @zoning.save
      end
      format.json { render action: 'edit' }
    end
  end

  def isochrone
    respond_to do |format|
      size = params.key?(:size) ? Integer(params[:size]) : 10
      if size
        @zoning.isochrone(size)
        @zoning.save
      end
      format.json { render action: 'edit' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_zoning
    @zoning = Zoning.find(params[:id] || params[:zoning_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def zoning_params
    params.require(:zoning).permit(:name, zones_attributes: [:id, :polygon, :_destroy, :vehicle_id])
  end
end
