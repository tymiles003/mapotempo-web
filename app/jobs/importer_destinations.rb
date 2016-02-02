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
      active: I18n.t('destinations.import_file.active'),
      stop_type: I18n.t('destinations.import_file.stop_type')
    }
  end

  def columns_destination
    {
      ref: I18n.t('destinations.import_file.ref'),
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
      tags: I18n.t('destinations.import_file.tags')
    }
  end

  def columns_visit
    {
      # Visit
      ref_visit: I18n.t('destinations.import_file.ref_visit'),
      open: I18n.t('destinations.import_file.open'),
      close: I18n.t('destinations.import_file.close'),
      tags_visit: I18n.t('destinations.import_file.tags_visit'),
      take_over: I18n.t('destinations.import_file.take_over'),
      quantity: I18n.t('destinations.import_file.quantity'),
    }
  end

  def columns
    columns_route.merge(columns_destination).merge(columns_visit).merge(without_visit: I18n.t('destinations.import_file.without_visit'))
  end

  def before_import(replace, name, synchronous)
    @common_tags = nil
    @tag_labels = Hash[@customer.tags.collect{ |tag| [tag.label, tag] }]
    @tag_ids = Hash[@customer.tags.collect{ |tag| [tag.id, tag] }]
    @routes = Hash.new{ |h, k| h[k] = [] }

    @planning = nil
    @need_geocode = false

    if replace
      @customer.delete_all_destinations
    end
    @visit_ids = []
  end

  def import_row(replace, name, row, line)
    if !row[:stop_type].nil? && row[:stop_type] != I18n.t('destinations.import_file.stop_type_visit')
      return
    end

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

    [:tags, :tags_visit].each{ |key|
      if !row[key].nil?
        if row[key].is_a?(String)
          row[key] = row[key].split(',').select{ |key|
            !key.empty?
          }
        end

        row[key] = row[key].collect{ |tag|
          if tag.is_a?(Fixnum)
            @tag_ids[tag]
          else
            if !@tag_labels.key?(tag)
              @tag_labels[tag] = @customer.tags.build(label: tag)
            end
            @tag_labels[tag]
          end
        }.compact
      elsif row.key?(key)
        row.delete key
      end
    }

    destination_attributes = row.slice(*(@@columns_destination_keys ||= columns_destination.keys))
    visit_attributes = row.slice(*(@@columns_visit_keys ||= columns_visit.keys))
    visit_attributes[:ref] = visit_attributes.delete :ref_visit
    visit_attributes[:tags] = visit_attributes.delete :tags_visit if visit_attributes.key?(:tags_visit)

    if !row[:ref].nil? && !row[:ref].strip.empty?
      destination = @customer.destinations.find{ |destination|
        destination.ref && destination.ref == row[:ref]
      }
      if destination
        destination.assign_attributes(destination_attributes)
      else
        destination = @customer.destinations.build(destination_attributes)
      end
      if row[:without_visit].nil? || row[:without_visit].strip.empty?
        if !row[:ref_visit].nil? && !row[:ref_visit].strip.empty?
          visit = destination.visits.find{ |visit|
            visit.ref && visit.ref == row[:ref_visit]
          }
        else
          # Get the first visit without ref
          visit = destination.visits.find{ |v| !v.ref }
        end
        if visit
          visit.assign_attributes(visit_attributes)
        else
          visit = destination.visits.build(visit_attributes)
        end
      else
        destination.visits = []
      end
    else
      if !row[:ref_visit].nil? && !row[:ref_visit].strip.empty?
        visit = @customer.visits.find{ |visit|
          visit.ref && visit.ref == row[:ref_visit]
        }
        if visit
          visit.destination.assign_attributes(destination_attributes)
          visit.assign_attributes(visit_attributes)
        end
      end
      if !visit
        # Get destination from attributes for multiple visits
        destination = @customer.destinations.find{ |d|
          d.attributes.symbolize_keys.slice(*columns_destination.keys).except(:customer_id, :lat, :lng, :geocoding_accuracy, :geocoding_level) == Hash[*columns_destination.keys.collect{ |v| [v, nil] }.flatten].merge(destination_attributes).except(:lat, :lng, :geocoding_accuracy, :geocoding_level, :tags)
        }
        if !destination
          destination = @customer.destinations.build(destination_attributes)
        end
        if row[:without_visit].nil? || row[:without_visit].strip.empty?
          # Link only when destination is complete
          visit = destination.visits.build(visit_attributes)
        end
      end
    end

    if visit
      if !name.nil?
        # Instersection of tags of all rows for tags of new planning
        if !@common_tags
          @common_tags = visit.tags.to_a
        else
          @common_tags &= visit.tags
        end
      end

      visit.save!

      # Add visit to route if needed
      if !@visit_ids.include?(visit.id)
        @routes[row.key?(:route) ? row[:route] : nil] << [visit, !row.key?(:active) || row[:active].strip != '0']
        @visit_ids << visit.id
      end

      visit.destination # For subclasses
    else
      destination.save! && destination
    end
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
    if @need_geocode && !synchronous && Mapotempo::Application.config.delayed_job_use
      @customer.job_destination_geocoding = Delayed::Job.enqueue(GeocoderDestinationsJob.new(@customer.id, @planning ? @planning.id : nil))
    else
      @planning.compute if @planning
    end

    @customer.save!
  end
end
