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
class V01::Destinations < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def destination_params
      p = ActionController::Parameters.new(params)
      p = p[:destination] if p.key?(:destination)
      p.permit(:ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :take_over, :open, :close, :comment, tag_ids: [])
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :destinations do
    desc 'Fetch customer\'s destinations.',
      nickname: 'getDestinations',
      is_array: true,
      entity: V01::Entities::Destination
    params do
      optional :ids, type: Array[String], desc: 'Select returned destinations by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: V01::CoerceArrayString
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
      params: V01::Entities::Destination.documentation.except(:id).merge(
        name: { required: true }
      ),
      entity: V01::Entities::Destination
    post do
      destination = current_customer.destinations.build(destination_params)
      destination.save!
      current_customer.save!
      present destination, with: V01::Entities::Destination
    end

    desc 'Import destinations by upload a CSV file or by JSON',
      nickname: 'importDestinations',
      params: V01::Entities::DestinationsImport.documentation
    put do
      if params['destinations']
        destinations_import = DestinationsImport.new
        destinations_import.assign_attributes(replace: params[:replace])
        ImporterDestinations.import_hash(destinations_import.replace, current_customer, params[:destinations])
        status 204
      else
        destinations_import = DestinationsImport.new
        destinations_import.assign_attributes(replace: params[:replace], file: params[:file])
        if destinations_import.valid?
          ImporterDestinations.import_csv(destinations_import.replace, current_customer, destinations_import.tempfile, destinations_import.name, true)
          status 204
        else
          error!({error: destinations_import.errors.full_messages}, 422)
        end
      end
    end

    desc 'Update destination.',
      nickname: 'updateDestination',
      params: V01::Entities::Destination.documentation.except(:id),
      entity: V01::Entities::Destination
    params do
      requires :id, type: String, desc: ID_DESC
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
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: V01::CoerceArrayString
    end
    delete do
      Destination.transaction do
        current_customer.destinations.select{ |destination|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, destination) }
        }.each(&:destroy)
      end
    end

    desc 'Geocode destination.',
      nickname: 'geocodeDestination',
      params: V01::Entities::Destination.documentation.except(:id),
      entity: V01::Entities::Destination
    patch 'geocode' do
      destination = Destination.new(destination_params)
      destination.geocode
      present destination, with: V01::Entities::Destination
    end

    if Mapotempo::Application.config.geocode_complete
      desc 'Auto completion on destination.',
        nickname: 'autocompleteDestination',
        params: V01::Entities::Destination.documentation.except(:id)
      patch 'geocode_complete' do
        p = destination_params
        address_list = Geocode.complete(current_customer.stores[0].lat, current_customer.stores[0].lng, 40000, p[:street], p[:postalcode], p[:city])
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
