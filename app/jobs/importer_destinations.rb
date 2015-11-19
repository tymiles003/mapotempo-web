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
require 'geocoder_destinations_job'

class ImporterDestinations < ImporterBase

  def max_lines
    Mapotempo::Application.config.max_destinations
  end

  def columns
    {
      ref: I18n.t('destinations.import_file.ref'),
      route: I18n.t('destinations.import_file.route'),
      name: I18n.t('destinations.import_file.name'),
      street: I18n.t('destinations.import_file.street'),
      detail: I18n.t('destinations.import_file.detail'),
      postalcode: I18n.t('destinations.import_file.postalcode'),
      city: I18n.t('destinations.import_file.city'),
      country: I18n.t('destinations.import_file.country'),
      lat: I18n.t('destinations.import_file.lat'),
      lng: I18n.t('destinations.import_file.lng'),
      geocoding_accuracy: I18n.t('destinations.import_file.geocoding_accuracy'),
      geocoding_level: I18n.t('destinations.import_file.geocoding_level'),
      open: I18n.t('destinations.import_file.open'),
      close: I18n.t('destinations.import_file.close'),
      comment: I18n.t('destinations.import_file.comment'),
      phone_number: I18n.t('destinations.import_file.phone_number'),
      tags: I18n.t('destinations.import_file.tags'),
      take_over: I18n.t('destinations.import_file.take_over'),
      quantity: I18n.t('destinations.import_file.quantity'),
      active: I18n.t('destinations.import_file.active')
    }
  end

  def before_import(replace, name, synchronous)
    @common_tags = nil
    @tags = Hash[@customer.tags.collect{ |tag| [tag.label, tag] }]
    @routes = Hash.new{ |h, k| h[k] = [] }

    @planning = nil
    @need_geocode = false

    if replace
      @customer.destinations_destroy_all
    end
  end

  def import_row(replace, name, row, line)
    if row[:name].nil? || (row[:city].nil? && row[:postalcode].nil? && (row[:lat].nil? || row[:lng].nil?))
      raise I18n.t('destinations.import_file.missing_data', line: line)
    end

    if !row[:lat].nil?
      row[:lat] = Float(row[:lat].tr(',', '.'))
    end
    if !row[:lng].nil?
      row[:lng] = Float(row[:lng].tr(',', '.'))
    end

    if row[:lat].nil? || row[:lng].nil?
      @eed_geocode = true
    end

    if !row[:tags].nil?
      row[:tags] = row[:tags].split(',').select { |key|
        !key.empty?
      }.collect { |key|
        if !@tags.key?(key)
          @tags[key] = @customer.tags.build(label: key)
        end
        @tags[key]
      }
    end

    if !row[:ref].nil? && !row[:ref].strip.empty?
      destination = @customer.destinations.find{ |destination|
        destination.ref && destination.ref == row[:ref]
      }
      destination.assign_attributes(row.except(:route, :active)) if destination
    end
    if !destination
      destination = @customer.destinations.build(row.except(:route, :active)) # Link only when destination is complete
    end

    if !name.nil?
      # Instersection of tags of all rows for tags of new planning
      if !@common_tags
        @common_tags = destination.tags.to_a
      else
        @common_tags &= destination.tags
      end
    end

    if destination.ref.nil? || @routes.size && !@routes.any?{ |k, r| r.any?{ |d| d && d[0]['ref'] == destination.ref }}
      @routes[row.key?(:route) ? row[:route] : nil] << [destination, !row.key?(:active) || row[:active].strip != '0']
    end

    destination # For subclasses
  end

  def after_import(replace, name, synchronous)
    if @need_geocode && (synchronous || !Mapotempo::Application.config.delayed_job_use)
      @routes.each{ |_key, destinations|
        destinations.each{ |destination_active|
          if destination_active[0].lat.nil? || destination_active[0].lng.nil?
            begin
              destination_active[0].geocode
            rescue
            end
          end
        }
      }
    end

    if @routes.size > 1 || !@routes.key?(nil)
      @planning = @customer.plannings.build(name: name || I18n.t('activerecord.models.planning') + ' ' + Time.now.strftime(' %Y-%m-%d %H:%M'), vehicle_usage_set: @customer.vehicle_usage_sets[0], tags: @common_tags || [])
      @planning.set_destinations(@routes, false)
      @planning.save!
    end

    @customer.save!
  end

  def finalize_import(replace, name, synchronous)
    if @need_geocode && (!synchronous || Mapotempo::Application.config.delayed_job_use)
      @customer.job_destination_geocoding = Delayed::Job.enqueue(GeocoderDestinationsJob.new(@customer.id, @planning ? @planning.id : nil))
    else
      @planning.compute if @planning
    end

    @customer.save!
    true
  end
end
