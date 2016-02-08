# Copyright © Mapotempo, 2014-2016
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

class V01::Destinations < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def destination_params
      p = ActionController::Parameters.new(params)
      p = p[:destination] if p.key?(:destination)
      if p[:visits]
        p[:visits_attributes] = p[:visits]
      end
      p.permit(:ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :comment, :phone_number, :geocoding_accuracy, :geocoding_level, tag_ids: [], visits_attributes: [:id, :ref, :quantity, :take_over, :open, :close, tag_ids: []])
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :destinations do
    desc 'Fetch customer\'s destinations.',
      nickname: 'getDestinations',
      is_array: true,
      entity: V01::Entities::Destination
    params do
      optional :ids, type: Array[String], desc: 'Select returned destinations by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    get do
      destinations = if params.key?(:ids)
        current_customer.destinations.select{ |destination|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, destination) }
        }
      else
        current_customer.destinations.load
      end
      present destinations, with: V01::Entities::Destination
    end

    desc 'Fetch destination.',
      nickname: 'getDestination',
      entity: V01::Entities::Destination
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read(params[:id])
      present current_customer.destinations.where(id).first!, with: V01::Entities::Destination
    end

    desc 'Create destination.',
      nickname: 'createDestination',
      params: V01::Entities::Destination.documentation.except(:id, :tag_ids).deep_merge(
        name: { required: true },
        geocoding_accuracy: { values: 0..1 }
      ),
      entity: V01::Entities::Destination
    params do
      optional :tag_ids, type: Array[Integer], desc: 'Ids separated by comma.', coerce_with: CoerceArrayInteger, documentation: { param_type: 'form' }
    end
    post do
      destination = current_customer.destinations.build(destination_params)
      destination.save!
      current_customer.save!
      present destination, with: V01::Entities::Destination
    end

    desc 'Import destinations by upload a CSV file, by JSON or from TomTom',
      nickname: 'importDestinations',
      params: V01::Entities::DestinationsImport.documentation,
      is_array: true,
      entity: [V01::Entities::Destination, V01::Entities::DestinationsImport]
    put do
      import = if params[:destinations]
        ImportJson.new(importer: ImporterDestinations.new(current_customer), replace: params[:replace], json: params[:destinations])
      elsif params[:remote]
        case params[:remote]
          when 'tomtom' then ImportTomtom.new(importer: ImporterDestinations.new(current_customer), customer: current_customer, replace: params[:replace])
        end
      else
        ImportCsv.new(importer: ImporterDestinations.new(current_customer), replace: params[:replace], file: params[:file])
      end

      if import && import.valid? && (destinations = import.import(true))
        case params[:remote]
          when 'tomtom' then status 202
          else present destinations, with: V01::Entities::Destination
        end
      else
        error!({error: import && import.errors.full_messages}, 422)
      end
    end

    desc 'Update destination.',
      detail: 'If want to force geocoding for a new address, you have to send empty lat/lng with new address.',
      nickname: 'updateDestination',
      params: V01::Entities::Destination.documentation.except(:id, :tag_ids).deep_merge(
        geocoding_accuracy: { values: 0..1 }
      ),
      entity: V01::Entities::Destination
    params do
      requires :id, type: String, desc: ID_DESC
      optional :tag_ids, type: Array[Integer], desc: 'Ids separated by comma.', coerce_with: CoerceArrayInteger, documentation: { param_type: 'form' }
    end
    put ':id' do
      id = ParseIdsRefs.read(params[:id])
      destination = current_customer.destinations.where(id).first!
      destination.assign_attributes(destination_params)
      destination.save!
      destination.customer.save! if destination.customer
      present destination, with: V01::Entities::Destination
    end

    desc 'Delete destination.',
      nickname: 'deleteDestination'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    delete ':id' do
      id = ParseIdsRefs.read(params[:id])
      current_customer.destinations.where(id).first!.destroy
    end

    desc 'Delete multiple destinations.',
      nickname: 'deleteDestinations'
    params do
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    delete do
      Destination.transaction do
        current_customer.destinations.select{ |destination|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, destination) }
        }.each(&:destroy)
      end
    end

    desc 'Geocode destination.',
      detail: 'Result of geocoding is not saved with this operation. You can use update operation to save the result of geocoding.',
      nickname: 'geocodeDestination',
      params: V01::Entities::Destination.documentation.except(:id, :visits_attributes).deep_merge(
        geocoding_accuracy: { values: 0..1 }
      ),
      entity: V01::Entities::Destination
    patch 'geocode' do
      destination = current_customer.destinations.build(destination_params.except(:id, :visits_attributes))
      destination.geocode
      present destination, with: V01::Entities::Destination
    end

    if Mapotempo::Application.config.geocode_complete
      desc 'Auto completion on destination.',
        nickname: 'autocompleteDestination',
        params: V01::Entities::Destination.documentation.except(:id, :visits_attributes)
      patch 'geocode_complete' do
        p = destination_params.except(:id, :visits_attributes)
        address_list = Mapotempo::Application.config.geocode_geocoder.complete(p[:street], p[:postalcode], p[:city], p[:country] || current_customer.default_country, current_customer.stores[0].lat, current_customer.stores[0].lng)
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
