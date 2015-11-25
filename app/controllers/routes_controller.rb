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
require 'tomtom'
require 'masternaut'
require 'alyacom'
require 'csv'
require 'value_to_boolean'
require 'zip'

class RoutesController < ApplicationController
  load_and_authorize_resource
  before_action :set_route, only: [:update]

  def show
    @export_stores = ValueToBoolean.value_to_boolean(params['stores'], true)
    respond_to do |format|
      format.html
      format.gpx do
        @gpx_track = !!params['track']
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.gpx"'
      end
      format.kml do
        response.headers['Content-Disposition'] = 'attachment; filename="' + filename + '.kml"'
      end
      format.kmz do
        stringio = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry(filename + '.kml')
          zio.write render_to_string(formats: :kml)
          store_img_path = 'marker-home.png'
          zio.put_next_entry(store_img_path)
          zio.print IO.read('public/' + store_img_path)
          (Vehicle.colors_table + ['#707070']).each { |color|
            img_path = 'point-' + color[1..-1] + '.png'
            zio.put_next_entry(img_path)
            zio.print IO.read('public/' + img_path)
          }
        end
        send_data stringio.string,
          type: 'application/vnd.google-earth.kmz',
          filename: filename + '.kmz'
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
          if params[:type] == 'waypoints'
            Tomtom.export_route_as_waypoints(@route)
          elsif params[:type] == 'orders'
            Tomtom.export_route_as_orders(@route)
          else
            Tomtom.clear(@route)
          end
          head :no_content
        rescue => e
          render json: e.message, status: :unprocessable_entity
        end
      end
      format.masternaut do
        begin
          Masternaut.export_route(@route)
          head :no_content
        rescue => e
          render json: e.message, status: :unprocessable_entity
        end
      end
      format.alyacom do
        begin
          Alyacom.export_route(@route)
          head :no_content
        rescue => e
          render json: e.message, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @route.update(route_params)
        format.html { redirect_to @route, notice: t('activerecord.successful.messages.updated', model: @route.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_route
    @route = Route.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def route_params
    params.require(:route).permit(:hidden, :locked, :ref, :color)
  end

  def filename
    (@route.planning.name + '_' + (@route.ref || @route.vehicle_usage.vehicle.name) +
      (@route.planning.customer.enable_orders && @route.planning.order_array ? '_' + @route.planning.order_array.name : '') +
      (@route.planning.date ? '_' + l(@route.planning.date) : '')
    ).tr('/', '-').delete('"')
  end
end
