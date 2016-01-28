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

class V01::Stores < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def store_params
      p = ActionController::Parameters.new(params)
      p = p[:store] if p.key?(:store)
      p.permit(:ref, :name, :street, :postalcode, :city, :country, :lat, :lng, :geocoding_accuracy, :geocoding_level, :color, :icon, :icon_size)
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :stores do
    desc 'Fetch customer\'s stores.',
      nickname: 'getStores',
      is_array: true,
      entity: V01::Entities::Store
    params do
      optional :ids, type: Array[String], desc: 'Select returned stores by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    get do
      stores = if params.key?(:ids)
        current_customer.stores.select{ |store|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, store) }
        }
      else
        current_customer.stores.load
      end
      present stores, with: V01::Entities::Store
    end

    desc 'Fetch store.',
      nickname: 'getStore',
      entity: V01::Entities::Store
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read(params[:id])
      present current_customer.stores.where(id).first!, with: V01::Entities::Store
    end

    desc 'Create store.',
      nickname: 'createStore',
      params: V01::Entities::Store.documentation.except(:id).deep_merge(
        name: { required: true },
        city: { required: true },
        geocoding_accuracy: { values: 0..1 }
      ),
      entity: V01::Entities::Store
    post do
      store = current_customer.stores.build(store_params)
      current_customer.save!
      present store, with: V01::Entities::Store
    end

    desc 'Import stores by upload a CSV file or by JSON.',
      nickname: 'importStores',
      params: V01::Entities::StoresImport.documentation,
      is_array: true,
      entity: V01::Entities::Store
    put do
      import = if params[:stores]
        ImportJson.new(importer: ImporterStores.new(current_customer), replace: params[:replace], json: params[:stores])
      else
        ImportCsv.new(importer: ImporterStores.new(current_customer), replace: params[:replace], file: params[:file])
      end

      if import && import.valid? && (stores = import.import(true))
        present stores, with: V01::Entities::Store
      else
        error!({error: import.errors.full_messages}, 422)
      end
    end

    desc 'Update store.',
      detail: 'If want to force geocoding for a new address, you have to send empty lat/lng with new address.',
      nickname: 'updateStore',
      params: V01::Entities::Store.documentation.except(:id).deep_merge(
        geocoding_accuracy: { values: 0..1 }
      ),
      entity: V01::Entities::Store
    params do
      requires :id, type: String, desc: ID_DESC
    end
    put ':id' do
      id = ParseIdsRefs.read(params[:id])
      store = current_customer.stores.where(id).first!
      store.assign_attributes(store_params)
      store.save!
      store.customer.save! if store.customer
      present store, with: V01::Entities::Store
    end

    desc 'Delete store.',
      detail: 'At least one remaining store is required after deletion.',
      nickname: 'deleteStore'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    delete ':id' do
      id = ParseIdsRefs.read(params[:id])
      current_customer.stores.where(id).first!.destroy!
    end

    desc 'Delete multiple stores.',
      detail: 'At least one remaining store is required after deletion.',
      nickname: 'deleteStores'
    params do
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    delete do
      Store.transaction do
        current_customer.stores.select{ |store|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, store) }
        }.each(&:destroy)
      end
    end

    desc 'Geocode store.',
      detail: 'Result of geocoding is not saved with this operation. You can use update operation to save the result of geocoding.',
      nickname: 'geocodeStore',
      params: V01::Entities::Store.documentation.except(:id).deep_merge(
        geocoding_accuracy: { values: 0..1 }
      ),
      entity: V01::Entities::Store
    patch 'geocode' do
      store = current_customer.stores.build(store_params)
      store.geocode
      present store, with: V01::Entities::Store
    end

    if Mapotempo::Application.config.geocode_complete
      desc 'Auto completion on store.',
        nickname: 'autocompleteStore',
        params: V01::Entities::Store.documentation.except(:id)
      patch 'geocode_complete' do
        p = store_params
        address_list = Mapotempo::Application.config.geocode_geocoder.complete(p[:street], p[:postalcode], p[:city], p[:country] || current_customer.default_country, current_customer.stores[0].lat, current_customer.stores[0].lng)
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
