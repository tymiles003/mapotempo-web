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
  after_action :warnings, only: [:create, :update]

  def index
    @customer = current_user.customer
    @destinations = request.format.html? ? current_user.customer.destinations : current_user.customer.destinations.includes(:tags, visits: :tags)
    @tags = current_user.customer.tags
    respond_to do |format|
      format.html
      format.json
      format.excel do
        data = render_to_string.gsub("\n", "\r\n")
        send_data Iconv.iconv('ISO-8859-1//translit//ignore', 'utf-8', data).join(''),
            type: 'text/csv',
            filename: t('activerecord.models.destinations.other') + '.csv'
      end
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="' + t('activerecord.models.destinations.other') + '.csv"'
      end
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
        flash.now[:error] = @destination.customer.errors.full_messages if !@destination.customer.errors.empty?
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      Destination.transaction do
        if @destination.update(destination_params) && @destination.customer.save
          format.html { redirect_to link_back || edit_destination_path(@destination), notice: t('activerecord.successful.messages.updated', model: @destination.class.model_name.human) }
        else
          flash.now[:error] = @destination.customer.errors.full_messages if !@destination.customer.errors.empty?
          format.html { render action: 'edit' }
        end
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
    @import_csv = ImportCsv.new
    @import_tomtom = ImportTomtom.new
    if current_user.customer.advanced_options
      advanced_options = JSON.parse(current_user.customer.advanced_options)
      @columns_default = advanced_options['import']['destinations']['spreadsheetColumnsDef'] if advanced_options['import'] && advanced_options['import']['destinations'] && advanced_options['import']['destinations']['spreadsheetColumnsDef']
    end
  end

  def upload_csv
    respond_to do |format|
      @import_csv = ImportCsv.new(import_csv_params.merge(importer: ImporterDestinations.new(current_user.customer)))
      if @import_csv.valid? && @import_csv.import
        format.html { redirect_to action: 'index' }
      else
        @import_tomtom = ImportTomtom.new
        if current_user.customer.advanced_options
          advanced_options = JSON.parse(current_user.customer.advanced_options)
          @columns_default = advanced_options['import']['destinations']['spreadsheetColumnsDef'] if advanced_options['import'] && advanced_options['import']['destinations'] && advanced_options['import']['destinations']['spreadsheetColumnsDef']
        end
        format.html { render action: 'import' }
      end
    end
  end

  def upload_tomtom
    @import_tomtom = ImportTomtom.new import_tomtom_params.merge(importer: ImporterDestinations.new(current_user.customer), customer: current_user.customer)
    if current_user.customer.tomtom? && @import_tomtom.valid? && @import_tomtom.import
      flash[:warning] = @import_tomtom.warnings.join(', ') if @import_tomtom.warnings.any?
      redirect_to destinations_path, notice: t('.success')
    else
      @import_csv = ImportCsv.new
      render action: :import
    end
  rescue DeviceServiceError => e
    redirect_to destination_import_path, alert: e.message
  end

  def clear
    Destination.transaction do
      current_user.customer.delete_all_destinations
    end
    respond_to do |format|
      format.html { redirect_to action: 'index' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_destination
    @destination = current_user.customer.destinations.find params[:id] || params[:destination_id]
  end

  def warnings
    flash[:warning] = @destination.warnings.join(', ') if @destination.warnings && @destination.warnings.any?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def destination_params
    params.require(:destination).permit(:ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment, :geocoding_accuracy, :geocoding_level, tag_ids: [], visits_attributes: [:id, :ref, :quantity1_1, :quantity1_2, :take_over, :open1, :close1, :open2, :close2, :_destroy, tag_ids: []])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def import_csv_params
    params.require(:import_csv).permit(:replace, :file, :delete_plannings, column_def: ImporterDestinations.new(current_user.customer).columns.keys)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def import_tomtom_params
    params.require(:import_tomtom).permit(:replace)
  end
end
