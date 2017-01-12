# Copyright © Mapotempo, 2015
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
class RestValidator < ActiveModel::Validator
  def validate(record)

    record.errors[:rest_start] << I18n.t('activerecord.errors.models.vehicle_usage.missing_rest_window') if record.default_rest_duration && record.default_rest_start.nil?
    record.errors[:rest_stop] << I18n.t('activerecord.errors.models.vehicle_usage.missing_rest_window') if record.default_rest_duration && record.default_rest_stop.nil?
    record.errors[:rest_duration] << I18n.t('activerecord.errors.models.vehicle_usage.missing_rest_duration') if record.default_rest_duration.nil? && record.default_rest_start
  
    open_seconds = !record.default_open.nil? ? Time.parse(record.default_open.to_s).seconds_since_midnight : 0
    close_seconds = !record.default_close.nil? ? Time.parse(record.default_close.to_s).seconds_since_midnight : 0
    rest_start_seconds = !record.default_rest_start.nil? ? Time.parse(record.default_rest_start.to_s).seconds_since_midnight : 0
    rest_end_seconds = !record.default_rest_stop.nil? ? Time.parse(record.default_rest_stop.to_s).seconds_since_midnight : 0
    service_time_start_seconds = !record.default_service_time_start.nil? ? Time.parse(record.default_service_time_start.to_s).seconds_since_midnight : 0
    service_time_end_seconds = !record.default_service_time_end.nil? ? Time.parse(record.default_service_time_end.to_s).seconds_since_midnight : 0

    working_day_start = open_seconds + service_time_start_seconds
    working_day_end = close_seconds - service_time_end_seconds

    if (working_day_end - working_day_start) <= service_time_start_seconds
      record.errors[:service_time_start] = I18n.t('activerecord.errors.models.vehicle_usage.service_range')
    elsif (working_day_end - working_day_start) <= service_time_end_seconds
      record.errors[:service_time_end] = I18n.t('activerecord.errors.models.vehicle_usage.service_range')
    elsif (working_day_end - working_day_start) <= (service_time_start_seconds + service_time_end_seconds)
      record.errors[:base] = I18n.t('activerecord.attributes.vehicle_usage.service_time_start') + ' / ' + I18n.t('activerecord.attributes.vehicle_usage.service_time_end') + ' ' + I18n.t('activerecord.errors.models.vehicle_usage.service_range')
    elsif rest_start_seconds != 0 && rest_end_seconds != 0
      if !(rest_start_seconds >= working_day_start) || !(rest_end_seconds <= working_day_end)
        record.errors[:base] = I18n.t('activerecord.errors.models.vehicle_usage.rest_range', start: Time.at(working_day_start).utc.strftime("%H:%M"), end: Time.at(working_day_end).utc.strftime("%H:%M"))
      end
    end

  end
end

class VehicleUsage < ActiveRecord::Base
  belongs_to :vehicle_usage_set

  belongs_to :vehicle
  belongs_to :store_start, class_name: 'Store', inverse_of: :vehicle_usage_starts
  belongs_to :store_stop, class_name: 'Store', inverse_of: :vehicle_usage_stops
  belongs_to :store_rest, class_name: 'Store', inverse_of: :vehicle_usage_rests
  has_many :routes, inverse_of: :vehicle_usage, autosave: true

  accepts_nested_attributes_for :vehicle, update_only: true
  validates_associated_bubbling :vehicle

  nilify_blanks
  validates_time :open, if: :open
  validates_time :close, on_or_after: :open, if: ->(vu) { vu.open && vu.close }
  validates_time :rest_start, if: :rest_start
  validates_time :rest_stop, on_or_after: :rest_start, if: ->(vu) { vu.rest_start && vu.rest_stop }

  validates_with RestValidator, fields: [:rest_duration, :rest_start, :rest_stop]

  validates_time :service_time_start, if: :service_time_start
  validates_time :service_time_end, if: :service_time_end

  before_validation :nilify_times
  before_update :update_out_of_date

  before_save :update_routes

  before_destroy :update_stops

  scope :active, ->{ where(active: true) }
  scope :for_customer, lambda{ |customer| joins(:vehicle_usage_set).where(vehicle_usage_sets: { customer_id: customer.id }) }

  amoeba do
    exclude_association :routes

    customize(lambda { |_original, copy|
      def copy.nilify_times; end

      def copy.update_out_of_date; end

      def copy.update_routes; end
    })
  end

  def default_open
    open || vehicle_usage_set.open
  end

  def default_close
    close || vehicle_usage_set.close
  end

  def default_store_start
    store_start || vehicle_usage_set.store_start
  end

  def default_store_stop
    store_stop || vehicle_usage_set.store_stop
  end

  def default_store_rest
    store_rest || vehicle_usage_set.store_rest
  end

  def default_rest_start
    rest_start || vehicle_usage_set.rest_start
  end

  def default_rest_stop
    rest_stop || vehicle_usage_set.rest_stop
  end

  def default_rest_duration
    rest_duration || vehicle_usage_set.rest_duration
  end

  def default_rest_duration?
    !default_rest_duration.nil?
  end

  def default_service_time_start
    service_time_start || vehicle_usage_set.service_time_start
  end

  def default_service_time_end
    service_time_end || vehicle_usage_set.service_time_end
  end

  def update_rest
    if default_rest_duration.nil?
      # No more rest
      routes.each{ |route|
        route.stops.select{ |stop| stop.is_a?(StopRest) }.each{ |stop|
          route.remove_stop(stop)
        }
      }
    else
      # New or changed rest
      routes.each(&:add_or_update_rest)
    end
  end

  private

  def update_routes
    return if changes.exclude?(:active)
    if active?
      vehicle_usage_set.plannings.each do |planning|
        planning.vehicle_usage_add self
        planning.save!
      end
    else
      vehicle_usage_set.plannings.each do |planning|
        planning.vehicle_usage_remove self
        planning.save!
      end
    end
  end

  def nilify_times
    assign_attributes(rest_duration: nil) if rest_duration.eql?(Time.new(2000, 1, 1, 0, 0, 0, '+00:00')) && vehicle_usage_set.rest_duration.nil?
    assign_attributes(service_time_start: nil) if service_time_start.eql?(Time.new(2000, 1, 1, 0, 0, 0, '+00:00')) && vehicle_usage_set.service_time_start.nil?
    assign_attributes(service_time_end: nil) if service_time_end.eql?(Time.new(2000, 1, 1, 0, 0, 0, '+00:00')) && vehicle_usage_set.service_time_end.nil?
  end

  def update_out_of_date
    if rest_duration_changed?
      update_rest
    end

    if open_changed? || close_changed? || store_start_id_changed? || store_stop_id_changed? || rest_start_changed? || rest_stop_changed? || rest_duration_changed? || store_rest_id_changed? || service_time_start_changed? || service_time_end_changed?
      routes.each{ |route|
        route.out_of_date = true
        route.optimized_at = route.last_sent_to = route.last_sent_at = nil
      }
    end
  end

  def update_stops
    vehicle_usage_set.plannings.each do |planning|
      planning.vehicle_usage_remove self
      planning.save!
    end
    routes.destroy_all
  end

end
