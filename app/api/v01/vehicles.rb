# Copyright © Mapotempo, 2014-2015
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
require 'coerce'

require Rails.root.join("lib/devices/device_helpers")
include Devices::Helpers

class V01::Vehicles < Grape::API

  rescue_from DeviceServiceError do |e|
    error! e.message, 200
  end

  helpers do
    def session
      env[Rack::Session::Abstract::ENV_SESSION_KEY]
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle] if p.key?(:vehicle)
      p.permit(:contact_email, :ref, :name, :emission, :consumption, :capacity, :capacity_unit, :color, :tomtom_id, :masternaut_ref, :router_id, :router_dimension, :speed_multiplicator)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_usage_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle] if p.key?(:vehicle)
      p.permit(:open, :close, :store_start_id, :store_stop_id, :store_rest_id, :rest_start, :rest_stop, :rest_duration)
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :vehicles do
    desc 'Fetch customer\'s vehicles.',
      nickname: 'getVehicles',
      is_array: true,
      entity: V01::Entities::Vehicle
    params do
      optional :ids, type: Array[String], desc: 'Select returned vehicles by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    get do
      vehicles = if params.key?(:ids)
        current_customer.vehicles.select{ |vehicle|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, vehicle) }
        }
      else
        current_customer.vehicles.load
      end
      present vehicles, with: V01::Entities::Vehicle
    end

    desc 'Get vehicle\'s position.',
      nickname: 'currentPosition',
      is_array: true,
      entity: V01::Entities::VehiclePosition
    params do
      optional :ids, type: Array[Integer]
    end
    get 'current_position' do
      customer = current_customer
      vehicles = customer.vehicles.find params[:ids]
      positions = [] ; errors = []
      begin
        if customer.orange?
          (OrangeService.new(customer: customer).get_vehicles_pos || []).each do |item|
            vehicle_id = item.delete :orange_vehicle_id
            vehicle = vehicles.detect{|v| v.orange_id == vehicle_id }
            next if !vehicle
            positions << item.merge(vehicle_id: vehicle.id)
          end
        end
      rescue DeviceServiceError => e
        errors << e.message
      end
      begin
        if customer.teksat?
          teksat_authenticate customer
          (TeksatService.new(customer: customer, ticket_id: session[:teksat_ticket_id]).get_vehicles_pos || []).each do |item|
            vehicle_id = item.delete :teksat_vehicle_id
            vehicle = vehicles.detect{|v| v.teksat_id == vehicle_id }
            next if !vehicle
            positions << item.merge(vehicle_id: vehicle.id)
          end
        end
      rescue DeviceServiceError => e
        errors << e.message
      end
      begin
        if customer.tomtom?
          (TomtomService.new(customer: customer).get_vehicles_pos || []).each do |item|
            vehicle_id = item.delete :tomtom_vehicle_id
            vehicle = vehicles.detect{|v| v.tomtom_id == vehicle_id }
            next if !vehicle
            positions << item.merge(vehicle_id: vehicle.id)
          end
        end
      rescue DeviceServiceError => e
        errors << e.message
      end
      if errors.any?
        { errors: errors }
      else
        present positions, with: V01::Entities::VehiclePosition
      end
    end

    desc 'Fetch vehicle.',
      nickname: 'getVehicle',
      entity: V01::Entities::Vehicle
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read(params[:id])
      present current_customer.vehicles.where(id).first!, with: V01::Entities::Vehicle
    end

    desc 'Update vehicle.',
      nickname: 'updateVehicle',
      params: V01::Entities::Vehicle.documentation.except(:id),
      entity: V01::Entities::Vehicle
    params do
      requires :id, type: String, desc: ID_DESC
    end
    put ':id' do
      id = ParseIdsRefs.read(params[:id])
      vehicle = current_customer.vehicles.where(id).first!
      vehicle.update! vehicle_params
      present vehicle, with: V01::Entities::Vehicle
    end

    detailCreate = 'For each new created <code>Vehicle</code> and <code>VehicleUsageSet</code> a new <code>VehicleUsage</code> will be created at the same time (i.e. customer has 2 VehicleUsageSets \'Morning\' and \'Evening\', a new Vehicle is created: 2 new VehicleUsages will be automatically created with the new vehicle.)'
    if Mapotempo::Application.config.manage_vehicles_only_admin
      detailCreate = 'Only available with an admin api_key. <br>' + detailCreate
    end
    desc 'Create vehicle.',
      detail: detailCreate,
      nickname: 'createVehicle',
      params: V01::Entities::Vehicle.documentation.except(:id).deep_merge(
        name: { required: true },
      ).deep_merge(V01::Entities::VehicleUsage.documentation.except(:id).except(:vehicle_usage_set)),
      entity: V01::Entities::Vehicle
    if Mapotempo::Application.config.manage_vehicles_only_admin
      params do
        requires :customer_id, type: Integer
      end
    end
    post do
      if Mapotempo::Application.config.manage_vehicles_only_admin
        if @current_user.admin?
          customer = @current_user.reseller.customers.where(id: params[:customer_id]).first!
          vehicle = customer.vehicles.create(vehicle_params)
          vehicle.vehicle_usages.each { |u|
            u.assign_attributes(vehicle_usage_params)
          }
          vehicle.save!
        else
          error! 'Forbidden', 403
        end
      else
        vehicle = current_customer.vehicles.create(vehicle_params)
        vehicle.vehicle_usages.each { |u|
          u.assign_attributes(vehicle_usage_params)
        }
        vehicle.save!
      end
      present vehicle, with: V01::Entities::Vehicle
    end

    detailDelete = Mapotempo::Application.config.manage_vehicles_only_admin ? 'Only available with an admin api_key.' : nil
    desc 'Delete vehicle.',
      detail: detailDelete,
      nickname: 'deleteVehicle'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    delete ':id' do
      id = ParseIdsRefs.read(params[:id])
      if Mapotempo::Application.config.manage_vehicles_only_admin
        if @current_user.admin?
          vehicle = Vehicle.joins(:customer).where(id.merge(customers: {reseller_id: @current_user.reseller.id})).first!
          vehicle.destroy!
        else
          error! 'Forbidden', 403
        end
      else
        current_customer.vehicles.where(id).first!.destroy!
      end
    end

    desc 'Delete multiple vehicles.',
      detail: detailDelete,
      nickname: 'deleteVehicles'
    params do
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    delete do
      Vehicle.transaction do
        if Mapotempo::Application.config.manage_vehicles_only_admin
          if @current_user.admin?
            Vehicle.joins(:customer).where(customers: {reseller_id: @current_user.reseller.id}).select{ |vehicle|
              params[:ids].any?{ |s| ParseIdsRefs.match(s, vehicle) }
            }.each(&:destroy!)
          else
            error! 'Forbidden', 403
          end
        else
          current_customer.vehicles.select{ |vehicle|
            params[:ids].any?{ |s| ParseIdsRefs.match(s, vehicle) }
          }.each(&:destroy!)
        end
      end
    end
  end
end
