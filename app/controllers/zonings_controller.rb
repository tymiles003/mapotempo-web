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
class ZoningsController < ApplicationController
  load_and_authorize_resource :except => :create
  before_action :set_zoning, only: [:show, :edit, :update, :destroy]

  # GET /zonings
  # GET /zonings.json
  def index
    @zonings = Zoning.where(customer_id: current_user.customer.id)
  end

  # GET /zonings/1
  # GET /zonings/1.json
  def show
  end

  # GET /zonings/new
  def new
    @zoning = Zoning.new
    @planning = params.key?(:planning_id) ? Planning.where(customer_id: current_user.customer.id, id: params[:planning_id]).first : nil
  end

  # GET /zonings/1/edit
  def edit
    @planning = params.key?(:planning_id) ? Planning.where(customer_id: current_user.customer.id, id: params[:planning_id]).first : nil
  end

  # POST /zonings
  # POST /zonings.json
  def create
    @zoning = Zoning.new(zoning_params)
    @zoning.customer = current_user.customer

    respond_to do |format|
      if @zoning.save
        format.html { redirect_to edit_zoning_path(@zoning, planning_id: params.key?(:planning_id) ? params[:planning_id] : nil), notice: t('activerecord.successful.messages.created', model: @zoning.class.model_name.human) }
        format.json { render action: 'show', status: :created, location: @zoning }
      else
        @planning = params.key?(:planning_id) ? Planning.where(customer_id: current_user.customer.id, id: params[:planning_id]).first : nil
        format.html { render action: 'new' }
        format.json { render json: @zoning.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /zonings/1
  # PATCH/PUT /zonings/1.json
  def update
    respond_to do |format|
      if @zoning.update(zoning_params)
        format.html { redirect_to edit_zoning_path(@zoning, planning_id: params.key?(:planning_id) ? params[:planning_id] : nil), notice: t('activerecord.successful.messages.updated', model: @zoning.class.model_name.human) }
        format.json { head :no_content }
      else
        @planning = params.key?(:planning_id) ? Planning.where(customer_id: current_user.customer.id, id: params[:planning_id]).first : nil
        format.html { render action: 'edit' }
        format.json { render json: @zoning.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zonings/1
  # DELETE /zonings/1.json
  def destroy
    @zoning.destroy
    respond_to do |format|
      format.html { redirect_to zonings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zoning
      @zoning = Zoning.find(params[:id] || params[:zoning_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def zoning_params
      params.require(:zoning).permit(:name, zones_attributes: [:id, :polygon, :_destroy, vehicle_ids: []])
    end
end
