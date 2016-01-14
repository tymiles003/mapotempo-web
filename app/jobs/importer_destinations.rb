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
require 'geocoder_destinations_job'

class ImporterDestinations < ImporterBase

  def max_lines
    Mapotempo::Application.config.max_destinations
  end

  def columns_route
    {
      route: I18n.t('destinations.import_file.route'),
      active: I18n.t('destinations.import_file.active')
    }
  end

  def columns_destination
    {
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
      phone_number: I18n.t('destinations.import_file.phone_number'),
      comment: I18n.t('destinations.import_file.comment'),
    }
  end

  def columns_visit
    {
      # Visit
      ref: I18n.t('destinations.import_file.ref'),
      open: I18n.t('destinations.import_file.open'),
      close: I18n.t('destinations.import_file.close'),
      tags: I18n.t('destinations.import_file.tags'),
      take_over: I18n.t('destinations.import_file.take_over'),
      quantity: I18n.t('destinations.import_file.quantity'),
    }
  end

  def columns
    columns_route.merge(columns_destination).merge(columns_visit)
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

    if !row[:lat].nil? && (row[:lat].is_a? String)
      row[:lat] = Float(row[:lat].tr(',', '.'))
    end
    if !row[:lng].nil? && (row[:lng].is_a? String)
      row[:lng] = Float(row[:lng].tr(',', '.'))
    end

    if row[:lat].nil? || row[:lng].nil?
      @need_geocode = true
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
      visit = @customer.visits.find{ |visit|
        visit.ref && visit.ref == row[:ref]
      }
      if visit
        visit.destination.assign_attributes(row.slice(*(@@columns_destination_keys ||= columns_destination.keys)))
        visit.assign_attributes(row.slice(*(@@columns_visit_keys ||= columns_visit.keys)))
      end
    end
    if !visit
      # Link only when destination is complete
      destination = @customer.destinations.build(row.slice(*(@@columns_destination_keys ||= columns_destination.keys)))
      visit = destination.visits.build(row.slice(*(@@columns_visit_keys ||= columns_visit.keys)))
    end

    if !name.nil?
      # Instersection of tags of all rows for tags of new planning
      if !@common_tags
        @common_tags = visit.tags.to_a
      else
        @common_tags &= visit.tags
      end
    end

    if visit.ref.nil? || @routes.size && !@routes.any?{ |k, r| r.any?{ |d| d && d[0]['ref'] == visit.ref } }
      @routes[row.key?(:route) ? row[:route] : nil] << [visit, !row.key?(:active) || row[:active].strip != '0']
    end

    visit.destination # For subclasses
  end

  def after_import(replace, name, synchronous)
    if @need_geocode && (synchronous || !Mapotempo::Application.config.delayed_job_use)
      @routes.each{ |_key, visits|
        visits.each{ |visit_active|
          if visit_active[0].destination.lat.nil? || visit_active[0].destination.lng.nil?
            begin
              visit_active[0].destination.geocode
            rescue
            end
          end
        }
      }
    end

    if @routes.size > 1 || !@routes.key?(nil)
      @planning = @customer.plannings.build(name: name || I18n.t('activerecord.models.planning') + ' ' + I18n.l(Time.now, format: :long), vehicle_usage_set: @customer.vehicle_usage_sets[0], tags: @common_tags || [])
      @planning.set_visits(@routes, false)
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
  end
end
