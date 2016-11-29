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

  def initialize(customer, planning_hash = nil)
    super customer
    @planning_hash = planning_hash || {}
  end

  def max_lines
    Mapotempo::Application.config.max_destinations
  end

  def columns_route
    {
      route: {title: I18n.t('destinations.import_file.route'), desc: I18n.t('destinations.import_file.route_desc'), format: I18n.t('destinations.import_file.format.string')},
      ref_vehicle: {title: I18n.t('destinations.import_file.ref_vehicle'), desc: I18n.t('destinations.import_file.ref_vehicle_desc'), format: I18n.t('destinations.import_file.format.string')},
      active: {title: I18n.t('destinations.import_file.active'), desc: I18n.t('destinations.import_file.active_desc'), format: I18n.t('destinations.import_file.format.yes_no')},
      stop_type: {title: I18n.t('destinations.import_file.stop_type'), desc: I18n.t('destinations.import_file.stop_type_desc'), format: I18n.t('destinations.import_file.stop_format')}
    }
  end

  def columns_destination
    {
      ref: {title: I18n.t('destinations.import_file.ref'), desc: I18n.t('destinations.import_file.ref_desc'), format: I18n.t('destinations.import_file.format.string')},
      name: {title: I18n.t('destinations.import_file.name'), desc: I18n.t('destinations.import_file.name_desc'), format: I18n.t('destinations.import_file.format.string'), required: I18n.t('destinations.import_file.format.required')},
      street: {title: I18n.t('destinations.import_file.street'), desc: I18n.t('destinations.import_file.street_desc'), format: I18n.t('destinations.import_file.format.string'), required: I18n.t('destinations.import_file.format.advisable')},
      detail: {title: I18n.t('destinations.import_file.detail'), desc: I18n.t('destinations.import_file.detail_desc'), format: I18n.t('destinations.import_file.format.string')},
      postalcode: {title: I18n.t('destinations.import_file.postalcode'), desc: I18n.t('destinations.import_file.postalcode_desc'), format: I18n.t('destinations.import_file.format.integer'), required: I18n.t('destinations.import_file.format.advisable')},
      city: {title: I18n.t('destinations.import_file.city'), desc: I18n.t('destinations.import_file.city_desc'), format: I18n.t('destinations.import_file.format.string'), required: I18n.t('destinations.import_file.format.advisable')},
      country: {title: I18n.t('destinations.import_file.country'), desc: I18n.t('destinations.import_file.country_desc'), format: I18n.t('destinations.import_file.format.string')},
      lat: {title: I18n.t('destinations.import_file.lat'), desc: I18n.t('destinations.import_file.lat_desc'), format: I18n.t('destinations.import_file.format.float')},
      lng: {title: I18n.t('destinations.import_file.lng'), desc: I18n.t('destinations.import_file.lng_desc'), format: I18n.t('destinations.import_file.format.float')},
      geocoding_accuracy: {title: I18n.t('destinations.import_file.geocoding_accuracy'), desc: I18n.t('destinations.import_file.geocoding_accuracy_desc'), format: I18n.t('destinations.import_file.format.float')},
      geocoding_level: {title: I18n.t('destinations.import_file.geocoding_level'), desc: I18n.t('destinations.import_file.geocoding_level_desc'), format: '[' + ::Destination::GEOCODING_LEVEL.keys.join(' | ') + ']'},
      phone_number: {title: I18n.t('destinations.import_file.phone_number'), desc: I18n.t('destinations.import_file.phone_number_desc'), format: I18n.t('destinations.import_file.format.integer')},
      comment: {title: I18n.t('destinations.import_file.comment'), desc: I18n.t('destinations.import_file.comment_desc'), format: I18n.t('destinations.import_file.format.string')},
      tags: {title: I18n.t('destinations.import_file.tags'), desc: I18n.t('destinations.import_file.tags_desc'), format: I18n.t('destinations.import_file.tags_format')}
    }
  end

  def columns_visit
    {
      # Visit
      ref_visit: {title: I18n.t('destinations.import_file.ref_visit'), desc: I18n.t('destinations.import_file.ref_visit_desc'), format: I18n.t('destinations.import_file.format.string')},
      open1: {title: I18n.t('destinations.import_file.open1'), desc: I18n.t('destinations.import_file.open1_desc'), format: I18n.t('destinations.import_file.format.hour')},
      close1: {title: I18n.t('destinations.import_file.close1'), desc: I18n.t('destinations.import_file.close1_desc'), format: I18n.t('destinations.import_file.format.hour')},
      open2: {title: I18n.t('destinations.import_file.open2'), desc: I18n.t('destinations.import_file.open2_desc'), format: I18n.t('destinations.import_file.format.hour')},
      close2: {title: I18n.t('destinations.import_file.close2'), desc: I18n.t('destinations.import_file.close2_desc'), format: I18n.t('destinations.import_file.format.hour')},
      tags_visit: {title: I18n.t('destinations.import_file.tags_visit'), desc: I18n.t('destinations.import_file.tags_visit_desc'), format: I18n.t('destinations.import_file.tags_format')},
      take_over: {title: I18n.t('destinations.import_file.take_over'), desc: I18n.t('destinations.import_file.take_over_desc'), format: I18n.t('destinations.import_file.format.second')},
      quantity1_1: {title: I18n.t('destinations.import_file.quantity1_1'), desc: I18n.t('destinations.import_file.quantity1_1_desc'), format: I18n.t('destinations.import_file.format.integer')},
      quantity1_2: {title: I18n.t('destinations.import_file.quantity1_2'), desc: I18n.t('destinations.import_file.quantity1_2_desc'), format: I18n.t('destinations.import_file.format.integer')},
    }
  end

  def columns
    columns_route.merge(columns_destination).merge(columns_visit).merge(
      without_visit: {title: I18n.t('destinations.import_file.without_visit'), desc: I18n.t('destinations.import_file.without_visit_desc'), format: I18n.t('destinations.import_file.format.yes_no')},
      # Deals with deprecated open and close
      open: {title: I18n.t('destinations.import_file.open'), desc: I18n.t('destinations.import_file.open_desc'), format: I18n.t('destinations.import_file.format.hour'), required: I18n.t('destinations.import_file.format.deprecated')},
      close: {title: I18n.t('destinations.import_file.close'), desc: I18n.t('destinations.import_file.close_desc'), format: I18n.t('destinations.import_file.format.hour'), required: I18n.t('destinations.import_file.format.deprecated')},
      # Deals with deprecated quantity
      quantity: {title: I18n.t('destinations.import_file.quantity'), desc: I18n.t('destinations.import_file.quantity_desc'), format: I18n.t('destinations.import_file.format.integer'), required: I18n.t('destinations.import_file.format.deprecated')}
    )
  end

  def json_to_rows(json)
    json.collect{ |dest|
      dest[:tags] = dest[:tag_ids].collect(&:to_i) if !dest.key?(:tags) && dest.key?(:tag_ids)
      if dest.key?(:visits) && !dest[:visits].empty?
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
    dest_ids = rows.collect(&:id).uniq
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
        hh[kk] = kk == :visits ? [] : nil
      }
    }

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

  def valid_row(destination, row, line)
    if destination.name.nil?
      raise ImportInvalidRow.new(I18n.t('destinations.import_file.missing_name', line: (row[:line] || line)))
    end
    if destination.city.nil? && destination.postalcode.nil? && (destination.lat.nil? || destination.lng.nil?)
      raise ImportInvalidRow.new(I18n.t('destinations.import_file.missing_location', line: (row[:line] || line)))
    end
  end

  def import_row(name, row, line, options)
    if !row[:stop_type].nil? && row[:stop_type] != I18n.t('destinations.import_file.stop_type_visit')
      return
    end

    # Deals with deprecated open and close
    row[:open1] = row.delete(:open) if !row.key?(:open1)
    row[:close1] = row.delete(:close) if !row.key?(:close1)
    # Deals with deprecated quantity
    row[:quantity1_1] = row.delete(:quantity) if !row.key?(:quantity1_1)

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
        visit = if !row[:ref_visit].nil? && !row[:ref_visit].strip.empty?
          destination.visits.find{ |visit|
            visit.ref && visit.ref == row[:ref_visit]
          }
        else
          # Get the first visit without ref
          destination.visits.find{ |v| !v.ref }
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

    valid_row(visit ? visit.destination : destination, row, line)

    if visit
      # Instersection of tags of all rows for tags of new planning
      if !@common_tags
        @common_tags = (visit.tags.to_a | visit.destination.tags.to_a)
      else
        @common_tags &= (visit.tags | visit.destination.tags)
      end

      if visit.destination.need_geocode?
        @destinations_to_geocode << visit.destination
        visit.destination.lat = nil # for job
      end
      visit.destination.delay_geocode
      visit.destination.validate! # to get errors first
      visit.save!

      # Add visit to route if needed
      if row.key?(:route) && !@visit_ids.include?(visit.id)
        @routes[row[:route]][:ref_vehicle] = row[:ref_vehicle].gsub(%r{[\./\\]}, ' ') if row[:ref_vehicle]
        @routes[row[:route]][:visits] << [visit, ValueToBoolean.value_to_boolean(row[:active], true)]
        @visit_ids << visit.id
      end

      visit.destination # For subclasses
    else
      if destination.need_geocode?
        @destinations_to_geocode << destination
        destination.lat = nil # for job
      end
      destination.delay_geocode
      destination.save!
      destination # For subclasses
    end
  end

  def after_import(name, options)
    if !@destinations_to_geocode.empty? && (@synchronous || !Mapotempo::Application.config.delayed_job_use)
      @destinations_to_geocode.each_slice(50){ |destinations|
        geocode_args = destinations.collect(&:geocode_args)
        begin
          results = Mapotempo::Application.config.geocode_geocoder.code_bulk(geocode_args)
          destinations.zip(results).each { |destination, result|
            destination.geocode_result(result) if result
          }
        rescue GeocodeError # avoid stop import because of geocoding job
        end
      }
    end

    @customer.save!

    if !@routes.keys.compact.empty?
      @planning = @customer.plannings.find_by(ref: @planning_hash['ref']) if @planning_hash.key?('ref')
      @planning = @customer.plannings.build if !@planning
      @planning.attributes = {
        name: name || I18n.t('activerecord.models.planning') + ' ' + I18n.l(Time.zone.now, format: :long),
        vehicle_usage_set: @customer.vehicle_usage_sets[0],
        tags: @common_tags || []
      }.merge(@planning_hash)

      @planning.set_routes @routes, false, true

      @planning.save!
    end

  end

  def finalize_import(name, options)
    if !@destinations_to_geocode.empty? && !@synchronous && Mapotempo::Application.config.delayed_job_use
      @customer.job_destination_geocoding = Delayed::Job.enqueue(GeocoderDestinationsJob.new(@customer.id, @planning ? @planning.id : nil))
    elsif @planning
      @planning.compute(ignore_errors: true)
    end

    @customer.save!
  end
end
