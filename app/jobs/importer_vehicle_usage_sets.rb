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

class ImporterVehicleUsageSets < ImporterBase

  def max_lines
    # Limit to the number of max vehicles and one for default configuration
    @customer.max_vehicles + 1
  end

  def columns_vehicle_usage_set
    {
        name_vehicle_usage_set: { title: I18n.t('vehicle_usage_sets.import.name_vehicle_usage_set'), desc: I18n.t('vehicle_usage_sets.import.name_desc'), format: I18n.t('vehicle_usage_sets.import.format.string'), required: I18n.t('vehicle_usage_sets.import.format.required_for_default') },
        open: { title: I18n.t('vehicle_usage_sets.import.open'), desc: I18n.t('vehicle_usage_sets.import.open_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour'), required: I18n.t('vehicle_usage_sets.import.format.required_for_default') },
        close: { title: I18n.t('vehicle_usage_sets.import.close'), desc: I18n.t('vehicle_usage_sets.import.close_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour'), required: I18n.t('vehicle_usage_sets.import.format.required_for_default') },
        store_start_ref: { title: I18n.t('vehicle_usage_sets.import.store_start_ref'), desc: I18n.t('vehicle_usage_sets.import.store_start_desc'), format: I18n.t('vehicle_usage_sets.import.format.string') },
        store_stop_ref: { title: I18n.t('vehicle_usage_sets.import.store_stop_ref'), desc: I18n.t('vehicle_usage_sets.import.store_stop_desc'), format: I18n.t('vehicle_usage_sets.import.format.string') },
        rest_start: { title: I18n.t('vehicle_usage_sets.import.rest_start'), desc: I18n.t('vehicle_usage_sets.import.rest_start_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour') },
        rest_stop: { title: I18n.t('vehicle_usage_sets.import.rest_stop'), desc: I18n.t('vehicle_usage_sets.import.rest_stop_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour') },
        rest_duration: { title: I18n.t('vehicle_usage_sets.import.rest_duration'), desc: I18n.t('vehicle_usage_sets.import.rest_duration_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour') },
        store_rest_ref: { title: I18n.t('vehicle_usage_sets.import.store_rest_ref'), desc: I18n.t('vehicle_usage_sets.import.store_rest_desc'), format: I18n.t('vehicle_usage_sets.import.format.string') },
        service_time_start: { title: I18n.t('vehicle_usage_sets.import.service_time_start'), desc: I18n.t('vehicle_usage_sets.import.service_time_start_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour') },
        service_time_end: { title: I18n.t('vehicle_usage_sets.import.service_time_end'), desc: I18n.t('vehicle_usage_sets.import.service_time_end_desc'), format: I18n.t('vehicle_usage_sets.import.format.hour') },
    }
  end

  def columns_vehicle
    {
        ref_vehicle: { title: I18n.t('vehicles.import.ref_vehicle'), desc: I18n.t('vehicles.import.ref_desc'), format: I18n.t('vehicles.import.format.string') },
        name_vehicle: { title: I18n.t('vehicles.import.name_vehicle'), desc: I18n.t('vehicles.import.name_desc'), format: I18n.t('vehicles.import.format.string'), required: I18n.t('vehicle_usage_sets.import.format.required') },
        contact_email: { title: I18n.t('vehicles.import.contact_email'), desc: I18n.t('vehicles.import.contact_email_desc'), format: I18n.t('vehicles.import.format.string') },
        emission: { title: I18n.t('vehicles.import.emission'), desc: I18n.t('vehicles.import.emission_desc'), format: '[' + ::Vehicle.emissions_table.map { |emission| emission[0] }.join(' | ') + ']' },
        consumption: { title: I18n.t('vehicles.import.consumption'), desc: I18n.t('vehicles.import.consumption_desc'), format: I18n.t('vehicles.import.format.float') }
    }.merge(Hash[@customer.deliverable_units.map { |du|
      ["capacity#{du.id}".to_sym, { title: I18n.t('vehicles.import.capacities') + (du.label ? '[' + du.label + ']' : ''), desc: I18n.t('vehicles.import.capacities_desc'), format: I18n.t('vehicles.import.format.float') }]
    }]).merge(
        {
            router_mode: { title: I18n.t('vehicles.import.router_mode'), desc: I18n.t('vehicles.import.router_mode_desc'), format: I18n.t('vehicles.import.format.string') },
            router_dimension: { title: I18n.t('vehicles.import.router_dimension'), desc: I18n.t('vehicles.import.router_dimension_desc'), format: I18n.t('vehicles.import.format.string') },
            router_options: { title: I18n.t('vehicles.import.router_options'), desc: I18n.t('vehicles.import.router_options_desc'), format: I18n.t('vehicles.import.format.string') },
            speed_multiplicator: { title: I18n.t('vehicles.import.speed_multiplicator'), desc: I18n.t('vehicles.import.speed_multiplicator_desc'), format: I18n.t('vehicles.import.format.integer') },
            color: { title: I18n.t('vehicles.import.color'), desc: I18n.t('vehicles.import.color_desc'), format: I18n.t('vehicles.import.format.string') },
            devices: { title: I18n.t('vehicles.import.devices'), desc: I18n.t('vehicles.import.devices_desc'), format: I18n.t('vehicles.import.format.string') }
        }
    )
  end

  def columns
    columns_vehicle_usage_set.merge(columns_vehicle)
  end

  def json_to_rows(json)
    json
  end

  def rows_to_json(rows)
    rows
  end

  def before_import(_name, data, options)
    if options[:line_shift] == 1
      # Create missing deliverable units if needed
      column_titles = data[0].is_a?(Hash) ? data[0].keys : data.size > 0 ? data[0].map { |a| a[0] } : []
      unit_labels = @customer.deliverable_units.map(&:label)
      column_titles.each { |capacity_name|
        capacities = Regexp.new("^#{I18n.t('vehicles.import.capacities')}\\[(.*)\\]$").match(capacity_name)
        if capacities && unit_labels.exclude?(capacities[1])
          unit_labels.delete_at(unit_labels.index(capacities[1])) if unit_labels.index(capacities[1])
          @customer.deliverable_units.build(label: capacities[1])
        end
      }
      @customer.save!
    end

    if options[:replace]
      @previous_vehicle_usage_set = @customer.vehicle_usage_sets.first
    end

    @vehicle_usage_set = nil
    @stores_by_ref = Hash[@customer.stores.select(&:ref).collect { |store| [store.ref, store] }]

    imported_vehicle_refs = data.map { |datum| datum[I18n.t('vehicles.import.ref_vehicle')] }
    @vehicles_by_ref = Hash[@customer.vehicles.select(&:ref).select { |vehicle| imported_vehicle_refs.include?(vehicle.ref) }.collect { |vehicle| [vehicle.ref, vehicle] }]
    @vehicles_without_ref = @customer.vehicles.to_a.select { |vehicle| vehicle.ref.to_s.empty? || !imported_vehicle_refs.include?(vehicle.ref) }
  end

  def prepare_capacities(row)
    capacities = {}
    row.each { |key, value|
      /^capacity([0-9]+)$/.match(key.to_s) { |m|
        capacities.merge!({ Integer(m[1]) => row.delete(m[0].to_sym) })
      }
    }
    row[:capacities] = capacities if capacities.length > 0
  end

  def import_row(_name, row, options)
    if row[:name_vehicle_usage_set].nil? && @vehicle_usage_set.nil?
      raise ImportInvalidRow.new(I18n.t('vehicle_usage_sets.import.missing_name'))
    elsif (row[:open].nil? || row[:close].nil?) && @vehicle_usage_set.nil?
      raise ImportInvalidRow.new(I18n.t('vehicle_usage_sets.import.missing_open_close'))
    elsif row[:name_vehicle].nil? && !@vehicle_usage_set.nil?
      raise ImportInvalidRow.new(I18n.t('vehicles.import.missing_name'))
    end

    prepare_capacities(row)

    if @vehicle_usage_set.nil?
      # With the first line, create vehicle usage set
      vehicle_usage_set_attributes = row.slice(*columns_vehicle_usage_set.keys)
      vehicle_usage_set_attributes[:name] = vehicle_usage_set_attributes[:name_vehicle_usage_set]
      vehicle_usage_set_attributes[:store_start] = @stores_by_ref[vehicle_usage_set_attributes[:store_start_ref].to_s.strip] || @customer.stores[0]
      vehicle_usage_set_attributes[:store_stop] = @stores_by_ref[vehicle_usage_set_attributes[:store_stop_ref].to_s.strip] || @customer.stores[0]
      vehicle_usage_set_attributes[:store_rest] = @stores_by_ref[vehicle_usage_set_attributes[:store_rest_ref].to_s.strip]
      @vehicle_usage_set = @customer.vehicle_usage_sets.build(vehicle_usage_set_attributes.except(:name_vehicle_usage_set, :store_start_ref, :store_stop_ref, :store_rest_ref))
      @vehicle_usage_set.save!

      return @vehicle_usage_set
    else
      # Then for each vehicle, create vehicle nd vehicle usage
      vehicle = if !row[:ref_vehicle].nil? && !row[:ref_vehicle].strip.empty? && @vehicles_by_ref[row[:ref_vehicle].strip]
                  @vehicles_by_ref[row[:ref_vehicle].strip]
                else
                  @vehicles_without_ref.shift
                end

      if options[:replace_vehicles]
        vehicle_attributes = row.slice(*columns_vehicle.keys, :capacities)
        vehicle_attributes[:ref] = vehicle_attributes.delete(:ref_vehicle)
        vehicle_attributes[:name] = vehicle_attributes.delete(:name_vehicle)
        vehicle_attributes[:color] = vehicle_attributes.delete(:color) || vehicle.color
        vehicle_attributes[:router] = Router.where(mode: vehicle_attributes.delete(:router_mode)).first
        vehicle_attributes[:router_options] = vehicle_attributes[:router_options] ? ActiveSupport::JSON.decode(vehicle_attributes.delete(:router_options)) : {}
        vehicle_attributes[:devices] = vehicle_attributes[:devices] ? ActiveSupport::JSON.decode(vehicle_attributes.delete(:devices)) : {}
        vehicle.assign_attributes(vehicle_attributes)
        vehicle.save!
      end

      vehicle_usage_attributes = row.slice(*columns_vehicle_usage_set.keys)
      vehicle_usage_attributes[:store_start] = @stores_by_ref[vehicle_usage_attributes.delete(:store_start_ref).to_s.strip]
      vehicle_usage_attributes[:store_stop] = @stores_by_ref[vehicle_usage_attributes.delete(:store_stop_ref).to_s.strip]
      vehicle_usage_attributes[:store_rest] = @stores_by_ref[vehicle_usage_attributes.delete(:store_rest_ref).to_s.strip]
      vehicle_usage = @vehicle_usage_set.vehicle_usages.where(vehicle: vehicle).first
      vehicle_usage.assign_attributes(vehicle_usage_attributes.except(:name_vehicle_usage_set))
      vehicle_usage.save!

      return vehicle_usage
    end
  end

  def after_import(_name, options)
    @customer.save!

    if options[:replace] && @previous_vehicle_usage_set && @vehicle_usage_set && @vehicle_usage_set.persisted?
      @previous_vehicle_usage_set.destroy!
    end
  end

  def finalize_import(_name, _options)
    @customer.save!
  end
end
