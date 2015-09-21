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
require 'importer_destinations'

class DestinationsController < ApplicationController
  include LinkBack

  load_and_authorize_resource
  before_action :set_destination, only: [:show, :edit, :update, :destroy]

  def index
    @customer = current_user.customer
    @destinations = current_user.customer.destinations
    @tags = current_user.customer.tags
    respond_to do |format|
      format.html
      format.json
      format.excel do
        data = render_to_string.gsub('\n', '\r\n')
        send_data Iconv.iconv('ISO-8859-1//translit//ignore', 'utf-8', data).join(''),
            type: 'text/csv',
            filename: 'destinations.csv'
      end
      format.csv
    end
  end

  def show
  end

  def new
    @destination = current_user.customer.destinations.build
    @destination.postalcode = current_user.customer.stores[0].postalcode
    @destination.city = current_user.customer.stores[0].city
  end

  def edit
  end

  def create
    @destination = current_user.customer.destinations.build(destination_params)

    respond_to do |format|
      if @destination.save && current_user.customer.save
        format.html { redirect_to link_back || edit_destination_path(@destination), notice: t('activerecord.successful.messages.created', model: @destination.class.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      begin
        Destination.transaction do
          @destination.update(destination_params)
          @destination.save!
          @destination.customer.save!
          format.html { redirect_to link_back || edit_destination_path(@destination), notice: t('activerecord.successful.messages.updated', model: @destination.class.model_name.human) }
        end
      rescue => e
        flash.now[:error] = e.message
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @destination.destroy
    respond_to do |format|
      format.html { redirect_to destinations_url }
    end
  end

  def import_template
    respond_to do |format|
      format.excel do
        data = render_to_string.gsub('\n', '\r\n')
        send_data Iconv.iconv('ISO-8859-1//translit//ignore', 'utf-8', data).join(''),
            type: 'text/csv',
            filename: 'import_template.csv'
      end
      format.csv
    end
  end

  def import
    @destinations_import = DestinationsImport.new
  end

  def upload
    @destinations_import = DestinationsImport.new
    respond_to do |format|
      begin
        @destinations_import.assign_attributes(destinations_import_params)
        @destinations_import.valid? || raise
        ImporterDestinations.import_csv(@destinations_import.replace, current_user.customer, @destinations_import.tempfile, @destinations_import.name)
        format.html { redirect_to action: 'index' }
      rescue => e
        flash.now[:error] = e.message
        format.html { render action: 'import', status: :unprocessable_entity }
      end
    end
  end

  def clear
    Destination.transaction do
      current_user.customer.destinations.delete_all
    end
    respond_to do |format|
      format.html { redirect_to action: 'index' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_destination
    @destination = Destination.find(params[:id] || params[:destination_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def destination_params
    params.require(:destination).permit(:ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :take_over, :open, :close, :comment, :geocoding_accuracy, :geocoding_level, tag_ids: [])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def destinations_import_params
    params.require(:destinations_import).permit(:replace, :file)
  end
end
