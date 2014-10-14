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
require 'matrix_job'
require 'csv'

class PlanningsController < ApplicationController
  load_and_authorize_resource :except => :create
  before_action :set_planning, only: [:show, :edit, :update, :destroy, :move, :refresh, :switch, :automatic_insert, :update_stop, :optimize_route, :active, :duplicate]

  def index
    @plannings = Planning.where(customer_id: current_user.customer.id)
  end

  def show
    respond_to do |format|
      format.html
      format.json
      format.gpx do
        response.headers['Content-Disposition'] = 'attachment; filename="'+@planning.name.gsub('"', '')+'.gpx"'
      end
      format.excel do
        data = render_to_string
        send_data data.encode('ISO-8859-1'),
            type: 'text/csv',
            filename: @planning.name.gsub('"','')+'.csv'
      end
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="'+@planning.name.gsub('"', '')+'.csv"'
      end
    end
  end

  def new
    @planning = Planning.new
  end

  def edit
  end

  def create
    respond_to do |format|
      begin
        Planning.transaction do
          @planning = current_user.customer.plannings.build(planning_params)
          @planning.save! # FIXME workaround, avoid create a second empty planning
          @planning.default_routes
          @planning.save!
        end

        format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.created', model: @planning.class.model_name.human) }
      rescue
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @planning.update(planning_params)
        format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @planning.destroy
    respond_to do |format|
      format.html { redirect_to plannings_url }
    end
  end

  def move
    respond_to do |format|
      begin
        Planning.transaction do
          params[:route_id] = params[:route_id].to_i
          route = @planning.routes.find{ |route| route.id == params[:route_id] }
          params[:destination_id] = params[:destination_id].to_i
          destination = current_user.customer.destinations.find{ |destination| destination.id == params[:destination_id] }

          route.move_destination(destination, params[:index].to_i + 1)
          if @planning.save
            @planning.reload
            format.json { render action: 'show', location: @planning }
          else
            @planning.reload
            format.json { render json: @planning.errors, status: :unprocessable_entity }
          end
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def refresh
    respond_to do |format|
      begin
        @planning.compute
        if @planning.save
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def switch
    respond_to do |format|
      begin
        route = @planning.routes.find{ |route| route.id == Integer(params["route_id"]) }
        vehicle = Vehicle.where(id: Integer(params["vehicle_id"]), customer: current_user.customer).first
        if route and vehicle and @planning.switch(route, vehicle) and @planning.compute and @planning.save
          format.html { redirect_to @planning, notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def automatic_insert
    respond_to do |format|
      begin
        @stop = Stop.where(route: @planning.routes[0], destination_id: params[:destination_id]).first
        if @stop
          Planning.transaction do
            @planning.automatic_insert(@stop)
            @planning.save!
            @planning.reload
            format.json { render action: 'show', location: @planning }
          end
        else
          format.json { render nothing: true , status: :unprocessable_entity }
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def update_stop
    respond_to do |format|
      begin
        params[:route_id] = params[:route_id].to_i
        @route = @planning.routes.find{ |route| route.id == params[:route_id] }
        params[:destination_id] = params[:destination_id].to_i
        @stop = @route.stops.find{ |stop| stop.destination_id == params[:destination_id] }
        if @route && @stop && @stop.update(stop_params) && @route.compute&& @planning.save
          format.json { render action: 'show', location: @planning }
        else
          format.json { render nothing: true , status: :unprocessable_entity }
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def optimize_route
    @route = Route.where(planning: @planning, id: params[:route_id]).first
    if @route
      respond_to do |format|
        if @route.stops.size == 0 or (Optimizer::optimize(current_user.customer, @planning, @route) && current_user.save)
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def active
    route = @planning.routes.find{ |route| route.id == params[:route_id].to_i }
    respond_to do |format|
      if route && route.active(params[:active].to_s.to_sym) && route.compute && @planning.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def duplicate
    respond_to do |format|
      begin
        @planning = @planning.amoeba_dup
        @planning.save!
        format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
      rescue StandardError => e
        flash[:error] = e.message
        format.html { render action: 'index' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_planning
      @planning = Planning.find(params[:id] || params[:planning_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def planning_params
      params.require(:planning).permit(:name, :zoning_id, :tag_ids => [])
    end

    def stop_params
      params.require(:stop).permit(:active)
    end
end
