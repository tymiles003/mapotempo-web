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
  before_action :set_planning, only: [:show, :edit, :update, :destroy, :move, :refresh, :switch, :automatic_insert, :update_stop, :optimize_route, :active, :duplicate, :reverse_order, :apply_zonings, :optimize]

  include PlanningExport

  def index
    @plannings = current_user.customer.plannings
    @customer = current_user.customer
  end

  def show
    @params = params
    respond_to do |format|
      format.html
      format.json
      format.gpx do
        @gpx_track = !!params['track']
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.gpx"'
      end
      format.kml do
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.kml"'
        render 'plannings/show', locals: { planning: @planning }
      end
      format.kmz do
        if params[:email]
          @planning.routes.joins(vehicle_usage: [:vehicle]).each do |route|
            next if !route.vehicle_usage.vehicle.contact_email
            vehicle = route.vehicle_usage.vehicle
            content = kmz_string_io(route: route, with_home_markers: true).string
            name = export_filename route.planning, route.ref || route.vehicle_usage.vehicle.name
            if Mapotempo::Application.config.delayed_job_use
              RouteMailer.delay.send_kmz_route current_user, I18n.locale, vehicle, route, name + '.kmz', content
            else
              RouteMailer.send_kmz_route(current_user, I18n.locale, vehicle, route, name + '.kmz', content).deliver_now
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
        @columns = (@params[:columns] && @params[:columns].split('|')) || export_columns
        data = render_to_string.gsub("\n", "\r\n")
        send_data Iconv.iconv('ISO-8859-1//translit//ignore', 'utf-8', data).join(''),
            type: 'text/csv',
            filename: filename + '.csv'
      end
      format.csv do
        @columns = (@params[:columns] && @params[:columns].split('|')) || export_columns
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.csv"'
      end
    end
  end

  def new
    @planning = current_user.customer.plannings.build
    @planning.vehicle_usage_set = current_user.customer.vehicle_usage_sets[0]
  end

  def edit
    @spreadsheet_columns = export_columns
    capabilities
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
        capabilities
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
        route = @planning.routes.find{ |route| route.id == Integer(params[:route_id]) }
        stop = nil
        @planning.routes.find{ |route| stop = route.stops.find{ |stop| stop.id == Integer(params[:stop_id]) } }
        stop_route_id_was = stop.route.id
        if @planning.move_stop(route, stop, params[:index] ? Integer(params[:index]) : nil) && @planning.save
          @planning.reload
          @routes = [route]
          @routes << @planning.routes.find{ |route| route.id == stop_route_id_was } if stop_route_id_was != route.id
          format.json { render action: 'show', location: @planning }
        else
          @planning.reload
          format.json { render json: @planning.errors, status: :unprocessable_entity }
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
      Planning.transaction do
        route = @planning.routes.find{ |route| route.id == Integer(params['route_id']) }
        route.update! last_sent_at: nil
        vehicle_usage_id_was = route.vehicle_usage.id
        vehicle_usage = @planning.vehicle_usage_set.vehicle_usages.find(Integer(params['vehicle_usage_id']))
        if route && vehicle_usage && @planning.switch(route, vehicle_usage) && @planning.save && @planning.compute && @planning.save
          @routes = [route]
          @routes << @planning.routes.find{ |route| route.vehicle_usage && route.vehicle_usage.id == vehicle_usage_id_was } if vehicle_usage_id_was != route.vehicle_usage.id
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def automatic_insert
    if params[:stop_ids] && !params[:stop_ids].empty?
      stop_ids = params[:stop_ids].collect{ |id| Integer(id) }
      stops = @planning.routes.collect{ |r| r.stops.select{ |s| stop_ids.include? s.id } }.flatten
      route_ids = stops.collect{ |s| s.route_id }.uniq
    else
      stops = @planning.routes.detect{ |r| !r.vehicle_usage }.stops
      route_ids = stops.any? ? [stops[0].route_id] : []
    end

    Planning.transaction do
      success = true
      stops.each do |stop|
        route = @planning.automatic_insert stop
        if route
          route_ids << route.id if route_ids.exclude?(route.id)
        else
          success = false
          break
        end
      end

      respond_to do |format|
        format.json do
          if success && @planning.save! && @planning.reload
            @routes = @planning.routes.select{ |r| route_ids.include? r.id }
            render action: :show
          else
            render nothing: true, status: :unprocessable_entity
          end
        end
      end
    end
  end

  def update_stop
    respond_to do |format|
      Planning.transaction do
        params[:route_id] = Integer(params[:route_id])
        @route = @planning.routes.find{ |route| route.id == params[:route_id] }
        params[:stop_id] = Integer(params[:stop_id])
        @stop = @route.stops.find{ |stop| stop.id == params[:stop_id] }
        if @route && @stop && @stop.update(stop_params) && @route.compute && @planning.save
          @routes = [@route]
          format.json { render action: 'show', location: @planning }
        else
          format.json { render nothing: true, status: :unprocessable_entity }
        end
      end
    end
  end

  def optimize
    global = ValueToBoolean::value_to_boolean(params[:global])
    respond_to do |format|
      if Optimizer.optimize(@planning, nil, global) && @planning.customer.save
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
        @routes = [route]
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
        @routes = [route]
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def duplicate
    respond_to do |format|
      @planning = @planning.duplicate
      @planning.save!
      format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
    end
  end

  def reverse_order
    route = @planning.routes.find{ |route| route.id == Integer(params[:route_id]) }
    respond_to do |format|
      if route && route.reverse_order && route.compute && @planning.save
        @routes = [route]
        format.json { render action: 'show', location: @planning }
      else
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  def apply_zonings
    @planning.zonings = params[:planning] && planning_params[:zoning_ids] ? current_user.customer.zonings.find(planning_params[:zoning_ids]) : []
    @planning.zoning_out_of_date = true
    @planning.compute
    if @planning.save && @planning.reload
      respond_to do |format|
        format.json do
          render action: :show
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @planning.errors, status: :unprocessable_entity
        end
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_planning
    @planning = if [:show, :edit, :optimize].include?(action_name.to_sym) && !request.format.html?
      current_user.customer.plannings.includes(routes: {stops: :visit}).find(params[:id] || params[:planning_id])
    else
      current_user.customer.plannings.find(params[:id] || params[:planning_id])
    end
  end

  def planning_params
    p = params.require(:planning).permit(:name, :ref, :date, :vehicle_usage_set_id, tag_ids: [], zoning_ids: [])
    p[:date] = Date.strptime(p[:date], I18n.t('time.formats.datepicker')).strftime(ACTIVE_RECORD_DATE_MASK) if !p[:date].blank?
    p
  end

  def stop_params
    params.require(:stop).permit(:active)
  end

  def filename
    export_filename @planning, @planning.ref
  end

  def export_columns
    [
      :route,
      :vehicle,
      :order,
      :stop_type,
      :active,
      :wait_time,
      :time,
      :distance,
      :drive_time,
      :out_of_window,
      :out_of_capacity,
      :out_of_drive_time,

      :ref,
      :name,
      :street,
      :detail,
      :postalcode,
      :city,
      :country,
      :lat,
      :lng,
      :comment,
      :phone_number,
      :tags,

      :ref_visit,
      :duration,
      @planning.customer.enable_orders ? :orders : :quantity1_1,
      @planning.customer.enable_orders ? nil : :quantity1_2,
      :open1,
      :close1,
      :open2,
      :close2,
      :tags_visit
    ].compact
  end

  def capabilities
    @isochrone = [[@planning.vehicle_usage_set, Zoning.new.isochrone?(@planning.vehicle_usage_set, false)]]
    @isochrone_capability = @isochrone.find(&:last)
    @isodistance = [[@planning.vehicle_usage_set, Zoning.new.isodistance?(@planning.vehicle_usage_set, false)]]
    @isodistance_capability = @isodistance.find(&:last)
  end
end
