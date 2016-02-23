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
require 'zip'

class PlanningsController < ApplicationController
  load_and_authorize_resource
  before_action :set_planning, only: [:show, :edit, :update, :destroy, :move, :refresh, :switch, :automatic_insert, :update_stop, :optimize_each_routes, :optimize_route, :active, :duplicate, :reverse_order]

  include PlanningExport

  def index
    @plannings = current_user.customer.plannings
    @customer = current_user.customer
  end

  def show
    @export_stores = ValueToBoolean.value_to_boolean(params['stores'], true)
    respond_to do |format|
      format.html
      format.json
      format.gpx do
        @gpx_track = !!params['track']
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.gpx"'
      end
      format.kml do
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.kml"'
        render "plannings/show", locals: { planning: @planning }
      end
      format.kmz do
        if params[:email]
          @planning.routes.joins(vehicle_usage: [:vehicle]).each do |route|
            next if !route.vehicle_usage.vehicle.contact_email
            vehicle = route.vehicle_usage.vehicle
            content = kmz_string_io(route: route, with_home_markers: true).string
            name = export_filename route.planning, route.ref || route.vehicle_usage.vehicle.name
            if Mapotempo::Application.config.delayed_job_use
              RouteMailer.delay.send_kmz_route current_user, vehicle, route, name + '.kmz', content
            else
              RouteMailer.send_kmz_route(current_user, vehicle, route, name + '.kmz', content).deliver_now
            end
          end
          head :no_content
        else
          send_data kmz_string_io(planning: @planning, with_home_markers: true).string,
            type: 'application/vnd.google-earth.kmz',
            filename: filename + '.kmz'
        end
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
          @planning.routes.select(&:vehicle_usage).each{ |route|
            if params[:type] == 'waypoints'
              Tomtom.export_route_as_waypoints(route) if route.vehicle_usage.vehicle.tomtom_id
            elsif params[:type] == 'orders'
              Tomtom.export_route_as_orders(route) if route.vehicle_usage.vehicle.tomtom_id
            else
              Tomtom.clear(route) if route.vehicle_usage.vehicle.tomtom_id
            end
          }
          head :no_content
        rescue TomTomError => e
          render json: e.message, status: :unprocessable_entity
        end
      end
      format.masternaut do
        begin
          @planning.routes.select(&:vehicle_usage).each{ |route|
            Masternaut.export_route(route) if route.vehicle_usage.vehicle.masternaut_ref
          }
          head :no_content
        rescue MasternautError => e
          render json: e.message, status: :unprocessable_entity
        end
      end
      format.alyacom do
        begin
          @planning.routes.select(&:vehicle_usage).each{ |route|
            Alyacom.export_route(route) if route.vehicle_usage.vehicle.customer.alyacom_association
          }
          head :no_content
        rescue AlyacomError => e
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
        if @planning.save
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
        ids = params['plannings'].keys.collect{ |i| Integer(i) }
        current_user.customer.plannings.select{ |planning| ids.include?(planning.id) }.each(&:destroy)
      end
      respond_to do |format|
        format.html { redirect_to plannings_url }
      end
    end
  end

  def move
    respond_to do |format|
      Planning.transaction do
        params[:route_id] = Integer(params[:route_id])
        route = @planning.routes.find{ |route| route.id == params[:route_id] }
        params[:stop_id] = Integer(params[:stop_id])
        stop = nil
        @planning.routes.find{ |route| stop = route.stops.find{ |stop| stop.id == params[:stop_id] } }
        route.move_stop(stop, Integer(params[:index]))
        if @planning.save
          @planning.reload
          format.json { render action: 'show', location: @planning }
        else
          @planning.reload
          format.json { render json: @planning.errors.full_messages, status: :unprocessable_entity }
        end
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
      vehicle_usage = @planning.vehicle_usage_set.vehicle_usages.find(Integer(params['vehicle_usage_id']))
      if route && vehicle_usage && @planning.switch(route, vehicle_usage) && @planning.compute && @planning.save
        format.html { redirect_to @planning, notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def automatic_insert
    respond_to do |format|
      stop_id = Integer(params[:stop_id])
      @stop = @planning.routes.collect{ |route| route.stops.find{ |stop| stop.id == stop_id } }.compact[0]

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
      params[:route_id] = Integer(params[:route_id])
      @route = @planning.routes.find{ |route| route.id == params[:route_id] }
      params[:stop_id] = Integer(params[:stop_id])
      @stop = @route.stops.find{ |stop| stop.id == params[:stop_id] }
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
      route = @planning.routes.find{ |route| route.id == Integer(params[:route_id]) }
      if route && Optimizer.optimize(@planning, route) && @planning.customer.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def active
    route = @planning.routes.find{ |route| route.id == Integer(params[:route_id]) }
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

  def reverse_order
    route = @planning.routes.find{ |route| route.id == Integer(params[:route_id]) }
    respond_to do |format|
      if route && route.reverse_order && route.compute && @planning.save
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
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
    params.require(:planning).permit(:name, :ref, :date, :vehicle_usage_set_id, :zoning_id, tag_ids: [])
  end

  def stop_params
    params.require(:stop).permit(:active)
  end

  def filename
    export_filename @planning, @planning.ref
  end
end
