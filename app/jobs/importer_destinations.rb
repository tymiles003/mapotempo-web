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
require 'value_to_boolean'

class ImporterDestinations < ImporterBase

  def max_lines
    Mapotempo::Application.config.max_destinations
  end

  def columns_route
    {
      route: I18n.t('destinations.import_file.route'),
      ref_vehicle: I18n.t('destinations.import_file.ref_vehicle'),
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

  def json_to_rows(json)
    json.collect{ |dest|
      dest[:tags] = dest[:tag_ids].collect(&:to_i) if !dest.key?(:tags) && dest.key?(:tag_ids)
      if dest.key?(:visits) && dest[:visits].size > 0
        dest[:visits].collect{ |v|
          v[:ref_visit] = v.delete(:ref)
          v[:tags_visit] = v[:tag_ids].collect(&:to_i) if !v.key?(:tags) && v.key?(:tag_ids)
          dest.except(:visits).merge(v)
        }
      else
        [dest.merge(without_visit: 'x')]
      end
    }.flatten
  end

  def rows_to_json(rows)
    dest_ids = rows.collect{ |d| d.id }.uniq
    @customer.destinations.select{ |d|
      dest_ids.include?(d.id)
    }
  end

  def before_import(name, options)
    @common_tags = nil
    @tag_labels = Hash[@customer.tags.collect{ |tag| [tag.label, tag] }]
    @tag_ids = Hash[@customer.tags.collect{ |tag| [tag.id, tag] }]
    @routes = Hash.new{ |h, k|
      h[k] = Hash.new{ |hh, kk|
        if kk == :visits
          hh[kk] = []
        else
          hh[kk] = nil
        end
      }
    }

    @planning = nil
    @destinations_to_geocode = []

    if options[:delete_plannings]
      @customer.plannings.delete_all
    end
    if options[:replace]
      @customer.delete_all_destinations
    end
    @visit_ids = []
  end

  def prepare_tags(row, key)
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
  end

  def import_row(name, row, line, options)
    if !row[:stop_type].nil? && row[:stop_type] != I18n.t('destinations.import_file.stop_type_visit')
      return
    end

    if row[:name].nil? || (row[:city].nil? && row[:postalcode].nil? && (row[:lat].nil? || row[:lng].nil?))
      raise ImportInvalidRow.new(I18n.t('destinations.import_file.missing_data', line: line))
    end

    if !row[:lat].nil? && (row[:lat].is_a? String)
      row[:lat] = Float(row[:lat].tr(',', '.'))
    end
    if !row[:lng].nil? && (row[:lng].is_a? String)
      row[:lng] = Float(row[:lng].tr(',', '.'))
    end

    [:tags, :tags_visit].each{ |key| prepare_tags row, key }

    destination_attributes = row.slice(*(@@col_dest_keys ||= columns_destination.keys))
    visit_attributes = row.slice(*(@@columns_visit_keys ||= columns_visit.keys))
    visit_attributes[:ref] = visit_attributes.delete :ref_visit
    visit_attributes[:tags] = visit_attributes.delete :tags_visit if visit_attributes.key?(:tags_visit)

    if !row[:ref].nil? && !row[:ref].strip.empty?
      destination = @customer.destinations.find{ |destination|
        destination.ref && destination.ref == row[:ref]
      }
      if destination
        destination.assign_attributes(destination_attributes.compact) # FIXME: don't use compact to overwrite database with row containing nil
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
          visit.assign_attributes(visit_attributes.compact) # FIXME: don't use compact to overwrite database with row containing nil
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
        row_compare_attr = (@@dest_attr_nil ||= Hash[*columns_destination.keys.collect{ |v| [v, nil] }.flatten]).merge(destination_attributes).except(:lat, :lng, :geocoding_accuracy, :geocoding_level, :tags).stringify_keys
        @@slice_attr ||= (@@col_dest_keys - [:customer_id, :lat, :lng, :geocoding_accuracy, :geocoding_level]).collect(&:to_s)
        # Get destination from attributes for multiple visits
        destination = @customer.destinations.find{ |d|
          d.attributes.slice(*@@slice_attr) == row_compare_attr
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
      # Instersection of tags of all rows for tags of new planning
      if !@common_tags
        @common_tags = (visit.tags.to_a | visit.destination.tags.to_a)
      else
        @common_tags &= (visit.tags | visit.destination.tags)
      end

      visit.destination.delay_geocode if !synchronous && Mapotempo::Application.config.delayed_job_use
      visit.save!

      # Add visit to route if needed
      if row.key?(:route) && !@visit_ids.include?(visit.id)
        @routes[row[:route]][:ref_vehicle] = row[:ref_vehicle] if row[:ref_vehicle]
        @routes[row[:route]][:visits] << [visit, ValueToBoolean.value_to_boolean(row[:active], true)]
        @visit_ids << visit.id
      end

      @destinations_to_geocode << visit.destination if row[:lat].nil? || row[:lng].nil?
      visit.destination # For subclasses
    else
      destination.delay_geocode if !synchronous && Mapotempo::Application.config.delayed_job_use
      destination.save!
      @destinations_to_geocode << destination if row[:lat].nil? || row[:lng].nil?
      destination # For subclasses
    end
  end

  def after_import(name, options)
    if @destinations_to_geocode.size > 0 && (synchronous || !Mapotempo::Application.config.delayed_job_use)
      @destinations_to_geocode.each{ |destination|
        if destination.lat.nil? || destination.lng.nil?
          begin
            destination.geocode
          rescue
          end
        end
      }
    end

    if @routes.size > 0
      @planning = @customer.plannings.build(name: name || I18n.t('activerecord.models.planning') + ' ' + I18n.l(Time.now, format: :long), vehicle_usage_set: @customer.vehicle_usage_sets[0], tags: @common_tags || [])
      @planning.set_routes(@routes, true, true)
      @planning.save!
    end

    @customer.save!
  end

  def finalize_import(name, options)
    if @destinations_to_geocode.size > 0 && !synchronous && Mapotempo::Application.config.delayed_job_use
      @customer.job_destination_geocoding = Delayed::Job.enqueue(GeocoderDestinationsJob.new(@customer.id, @planning ? @planning.id : nil))
    else
      @planning.compute if @planning
    end

    @customer.save!
  end
end
