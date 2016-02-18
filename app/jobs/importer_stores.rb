# Copyright © Mapotempo, 2013-2016
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

  def max_lines
    Mapotempo::Application.config.max_destinations / 10
  end

  def columns
    {
      ref: I18n.t('stores.import_file.ref'),
      name: I18n.t('stores.import_file.name'),
      street: I18n.t('stores.import_file.street'),
      postalcode: I18n.t('stores.import_file.postalcode'),
      city: I18n.t('stores.import_file.city'),
      country: I18n.t('stores.import_file.country'),
      lat: I18n.t('stores.import_file.lat'),
      lng: I18n.t('stores.import_file.lng'),
      color: I18n.t('stores.import_file.color'),
      icon: I18n.t('stores.import_file.icon'),
      icon_size: I18n.t('stores.import_file.icon_size'),
      geocoding_accuracy: I18n.t('stores.import_file.geocoding_accuracy'),
      geocoding_level: I18n.t('stores.import_file.geocoding_level')
    }
  end

  def json_to_rows(json)
    json
  end

  def rows_to_json(rows)
    rows
  end

  def before_import(name, options)
    @need_geocode = false

    if options[:replace]
      # vehicle is always linked to a store
      @tmp_store = @customer.stores.build(
        name: I18n.t('stores.default.name'),
        city: I18n.t('stores.default.city'),
        lat: Float(I18n.t('stores.default.lat')),
        lng: Float(I18n.t('stores.default.lng'))
      )
      @customer.vehicle_usage_sets.each{ |vehicle_usage_set|
        vehicle_usage_set.store_start = @tmp_store
        vehicle_usage_set.store_stop = @tmp_store
      }
      @customer.save!
      @customer.stores.each{ |store|
        if store != @tmp_store
          @customer.stores.destroy(store)
        end
      }
    end
  end

  def import_row(name, row, line, options)
    if row[:name].nil? || (row[:city].nil? && row[:postalcode].nil? && (row[:lat].nil? || row[:lng].nil?))
      raise ImportInvalidRow.new(I18n.t('stores.import_file.missing_data', line: line))
    end

    if !row[:lat].nil? && (row[:lat].is_a? String)
      row[:lat] = Float(row[:lat].tr(',', '.'))
    end
    if !row[:lng].nil? && (row[:lng].is_a? String)
      row[:lng] = Float(row[:lng].tr(',', '.'))
    end

    if row[:lat].nil? || row[:lng].nil?
      @need_geocode = true
    end

    if !row[:ref].nil? && !row[:ref].strip.empty?
      store = @customer.stores.find{ |store|
        store.ref && store.ref == row[:ref]
      }
      store.assign_attributes(row) if store
    end
    if !store
      store = @customer.stores.build(row) # Link only when store is complete
    end

    store # For subclasses
  end

  def after_import(name, options)
    if options[:replace]
      if !@customer.stores[1].nil?
        @customer.vehicle_usage_sets.each{ |vehicle_usage_set|
          vehicle_usage_set.store_start = @customer.stores[1]
          vehicle_usage_set.store_stop = @customer.stores[1]
          vehicle_usage_set.save!
        }
      end
      @customer.stores.destroy(@tmp_store)
    end

    @customer.save!
  end

  def finalize_import(name, options)
    if @need_geocode && !synchronous && Mapotempo::Application.config.delayed_job_use
      @customer.job_store_geocoding = Delayed::Job.enqueue(GeocoderStoresJob.new(@customer.id))
    end

    @customer.save!
    true
  end
end
