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
require 'importer_base'
require 'geocoder_stores_job'

class ImporterStores < ImporterBase

  @max_lines = Mapotempo::Application.config.max_destinations / 10

  def self.columns
    {
      ref: I18n.t('stores.import_file.ref'),
      name: I18n.t('stores.import_file.name'),
      street: I18n.t('stores.import_file.street'),
      postalcode: I18n.t('stores.import_file.postalcode'),
      city: I18n.t('stores.import_file.city'),
      country: I18n.t('stores.import_file.country'),
      lat: I18n.t('stores.import_file.lat'),
      lng: I18n.t('stores.import_file.lng'),
      geocoding_accuracy: I18n.t('stores.import_file.geocoding_accuracy'),
      geocoding_level: I18n.t('stores.import_file.geocoding_level')
    }
  end

  private

  def self.import(replace, customer, data, name, synchronous)
    need_geocode = false

    line = 0

    Store.transaction do
      if replace
        # vehicle is always linked to a store
        tmp_store = customer.stores.build(
          name: I18n.t('stores.default.name'),
          city: I18n.t('stores.default.city'),
          lat: Float(I18n.t('stores.default.lat')),
          lng: Float(I18n.t('stores.default.lng'))
        )
        customer.vehicles.each{ |vehicle|
          vehicle.store_start = tmp_store
          vehicle.store_stop = tmp_store
        }
        customer.save!
        customer.stores.each{ |store|
          if store != tmp_store
            customer.stores.destroy(store)
          end
        }
      end

      data.each{ |row|
        row = yield(row)

        if row.size == 0
          next # Skip empty line
        end

        line += 1

        if row[:name].nil? || (row[:city].nil? && row[:postalcode].nil? && (row[:lat].nil? || row[:lng].nil?))
          raise I18n.t('stores.import_file.missing_data', line: line)
        end

        if !row[:lat].nil?
          row[:lat] = Float(row[:lat].gsub(',', '.'))
        end
        if !row[:lng].nil?
          row[:lng] = Float(row[:lng].gsub(',', '.'))
        end

        if row[:lat].nil? || row[:lng].nil?
          need_geocode = true
        end

        if !row[:ref].nil? && !row[:ref].strip.empty?
          store = customer.stores.find{ |store|
            store.ref && store.ref == row[:ref]
          }
          store.assign_attributes(row) if store
        end
        if !store
          customer.stores.build(row) # Link only when store is complete
        end
      }

      if replace
        if !customer.stores[1].nil?
          customer.vehicles.each{ |vehicle|
            vehicle.store_start = customer.stores[1]
            vehicle.store_stop = customer.stores[1]
            vehicle.save!
          }
        end
        customer.stores.destroy(tmp_store)
      end

      customer.save!
    end

    if need_geocode && (!synchronous || Mapotempo::Application.config.delayed_job_use)
      customer.job_store_geocoding = Delayed::Job.enqueue(GeocoderStoresJob.new(customer.id))
    end

    customer.save!
    true
  end

end
