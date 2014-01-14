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
require 'csv'
require 'importer'

class DestinationsController < ApplicationController
  load_and_authorize_resource :except => [:create, :upload]
  before_action :set_destination, only: [:show, :edit, :update, :destroy]

  # GET /destinations
  # GET /destinations.json
  def index
    @destinations = Destination.where(customer_id: current_user.customer.id)
    @tags = current_user.customer.tags
  end

  # GET /destinations/1
  # GET /destinations/1.json
  def show
  end

  # GET /destinations/new
  def new
    @destination = current_user.customer.store.dup
    @destination.name = ""
  end

  # GET /destinations/1/edit
  def edit
  end

  # POST /destinations
  # POST /destinations.json
  def create
    respond_to do |format|
      begin
        Destination.transaction do
          @destination = Destination.new(destination_params)
          @destination.customer = current_user.customer
          current_user.customer.destination_add(@destination)

          current_user.customer.save!
          format.html { redirect_to edit_destination_path(@destination), notice: t('activerecord.successful.messages.created', model: @destination.class.model_name.human) }
          format.json { render action: 'show', status: :created, location: @destination }
        end
      rescue StandardError => e
        format.html { render action: 'new' }
        format.json { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /destinations/1
  # PATCH/PUT /destinations/1.json
  def update
    respond_to do |format|
      begin
        @destination.assign_attributes(destination_params)
        !params[:reverse] or @destination.reverse_geocode
        @destination.save!
        current_user.save!

        format.html { redirect_to edit_destination_path(@destination), notice: t('activerecord.successful.messages.updated', model: @destination.class.model_name.human) }
        format.json { render action: 'show', location: @destination }
      rescue StandardError => e
        format.html { render action: 'edit' }
        format.json { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /destinations/1
  # DELETE /destinations/1.json
  def destroy
    @destination.destroy
    respond_to do |format|
      format.html { redirect_to destinations_url }
      format.json { head :no_content }
    end
  end

  def geocode
    respond_to do |format|
      begin
        @destination = Destination.new(destination_params)
        @destination.geocode
        format.json { render action: 'show', location: @destination }
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def geocode_reverse
    respond_to do |format|
      begin
        @destination = Destination.new(destination_params)
        @destination.reverse_geocode
        format.json { render action: 'show', location: @destination }
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def geocode_complete
    p = destination_params
    address_list = Geocode.complete(current_user.customer.store.lat, current_user.customer.store.lng, 40000, p[:street], p[:postalcode], p[:city])
    address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
    respond_to do |format|
      format.html
      format.json { render json: address_list.to_json }
    end
  end

  def import
  end

  def upload
    replace = params[:replace]
    file = params[:upload][:datafile].tempfile
    name = params[:upload][:datafile].original_filename.split('.')[0..-2].join('.')

    respond_to do |format|
      begin
        Importer.import(replace, current_user.customer, file, name) and current_user.save!
        format.html { redirect_to action: 'index' }
      rescue StandardError => e
        flash[:error] = e.message
        format.html { render action: 'import', status: :unprocessable_entity }
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
      params.require(:destination).permit(:name, :street, :detail, :postalcode, :city, :lat, :lng, :quantity, :open, :close, :comment, :tag_ids => [])
    end
end
