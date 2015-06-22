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
require 'csv'
require 'value_to_boolean'

class PlanningsController < ApplicationController
  load_and_authorize_resource except: :create
  before_action :set_planning, only: [:show, :edit, :update, :destroy, :move, :refresh, :switch, :automatic_insert, :update_stop, :optimize_each_routes, :optimize_route, :active, :duplicate]

  def index
    @plannings = current_user.customer.plannings
  end

  def show
    @export_stores = ValueToBoolean.value_to_boolean(params['stores'], true)
    respond_to do |format|
      format.html
      format.json
      format.gpx do
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.gpx"'
      end
      format.excel do
        data = render_to_string.gsub('\n', '\r\n')
        send_data Iconv.iconv('ISO-8859-1//translit//ignore', 'utf-8', data).join(''),
            type: 'text/csv',
            filename: filename + '.csv'
      end
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.csv"'
      end
      format.tomtom do
        begin
          @planning.routes.select(&:vehicle).each{ |route|
            if params[:type] == 'waypoints'
              Tomtom.export_route_as_waypoints(route) if route.vehicle.tomtom_id
            elsif params[:type] == 'orders'
              Tomtom.export_route_as_orders(route) if route.vehicle.tomtom_id
            else
              Tomtom.clear(route) if route.vehicle.tomtom_id
            end
          }
          head :no_content
        rescue => e
          render json: e.message, status: :unprocessable_entity
        end
      end
      format.masternaut do
        begin
          @planning.routes.select(&:vehicle).each{ |route|
            Masternaut.export_route(route) if route.vehicle.masternaut_ref
          }
          head :no_content
        rescue => e
          render json: e.message, status: :unprocessable_entity
        end
      end
      format.alyacom do
        begin
          @planning.routes.select(&:vehicle).each{ |route|
            Alyacom.export_route(route) if route.vehicle.customer.alyacom_association
          }
          head :no_content
        rescue => e
          render json: e.message, status: :unprocessable_entity
        end
      end
    end
  end

  def new
    @planning = current_user.customer.plannings.build()
  end

  def edit
  end

  def create
    respond_to do |format|
      Planning.transaction do
        @planning = current_user.customer.plannings.build(planning_params)
        if @planning.default_routes && @planning.save
          format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.created', model: @planning.class.model_name.human) }
        else
          format.html { render action: 'new' }
        end
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

  def destroy_multiple
    Planning.transaction do
      if params['plannings']
        ids = params['plannings'].keys.collect(&:to_i)
        current_user.customer.plannings.select{ |planning| ids.include?(planning.id) }.each(&:destroy)
      end
      respond_to do |format|
        format.html { redirect_to plannings_url }
      end
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
          route.move_destination(destination, params[:index].to_i)
          @planning.save!
          @planning.reload
          format.json { render action: 'show', location: @planning }
        end
      rescue => e
        @planning.reload
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def refresh
    respond_to do |format|
      @planning.compute
      if @planning.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def switch
    respond_to do |format|
      route = @planning.routes.find{ |route| route.id == Integer(params['route_id']) }
      vehicle = @planning.customer.vehicles.find(Integer(params['vehicle_id']))
      if route && vehicle && @planning.switch(route, vehicle) && @planning.compute && @planning.save
        format.html { redirect_to @planning, notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def automatic_insert
    respond_to do |format|
      stop_id = Integer(params[:destination_id])
      @stop = @planning.routes.collect{ |route| route.stops.find{ |stop| stop.destination.id == stop_id } }.select{ |i| i }[0]

      if @stop
        Planning.transaction do
          @planning.automatic_insert(@stop)
          @planning.save!
          @planning.reload
          format.json { render action: 'show', location: @planning }
        end
      else
        format.json { render nothing: true, status: :unprocessable_entity }
      end
    end
  end

  def update_stop
    respond_to do |format|
      params[:route_id] = params[:route_id].to_i
      @route = @planning.routes.find{ |route| route.id == params[:route_id] }
      params[:destination_id] = params[:destination_id].to_i
      @stop = @route.stops.find{ |stop| stop.destination_id == params[:destination_id] }
      if @route && @stop && @stop.update(stop_params) && @route.compute && @planning.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render nothing: true, status: :unprocessable_entity }
      end
    end
  end

  def optimize_each_routes
    respond_to do |format|
      if Optimizer.optimize_each(@planning) && @planning.customer.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def optimize_route
    respond_to do |format|
      route = @planning.routes.find{ |route| route.id == params[:route_id].to_i }
      if route && Optimizer.optimize(@planning, route) && @planning.customer.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
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
      @planning = @planning.amoeba_dup
      @planning.save!
      format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_planning
    @planning = Planning.find(params[:id] || params[:planning_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def planning_params
    params.require(:planning).permit(:name, :ref, :date, :zoning_id, tag_ids: [])
  end

  def stop_params
    params.require(:stop).permit(:active)
  end

  def filename
    (@planning.name + (@planning.ref ? '_' + @planning.ref : '') +
      (@planning.customer.enable_orders && @planning.order_array ? '_' + @planning.order_array.name : '') +
      (@planning.date ? '_' + l(@planning.date) : '')
    ).gsub('/', '-').gsub('"', '')
  end
end
