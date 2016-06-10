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
class VehicleUsageSet < ActiveRecord::Base
  belongs_to :customer
  belongs_to :store_start, class_name: 'Store', inverse_of: :vehicle_usage_set_starts
  belongs_to :store_stop, class_name: 'Store', inverse_of: :vehicle_usage_set_stops
  belongs_to :store_rest, class_name: 'Store', inverse_of: :vehicle_usage_set_rests
  has_many :plannings, inverse_of: :vehicle_usage_set
  before_destroy :destroy_vehicle_usage_set # Update planning.vehicle_usage_set before destroy self
  has_many :vehicle_usages, -> { order(:id) }, inverse_of: :vehicle_usage_set, dependent: :delete_all, autosave: true

  nilify_blanks
  auto_strip_attributes :name
  validates :customer, presence: true
  validates :store_start, presence: true
  validates :name, presence: true
  validates_time :open, presence: true
  validates_time :close, presence: true, after: :open
  validates_time :rest_start, if: :rest_start
  validates_time :rest_stop, on_or_after: :rest_start, if: :rest_stop

  validates :rest_start, presence: {if: :rest_duration?, message: lambda { |*_| I18n.t('activerecord.errors.models.vehicle_usage_set.missing_rest_window') }}
  validates :rest_stop, presence: {if: :rest_duration?, message: lambda { |*_| I18n.t('activerecord.errors.models.vehicle_usage_set.missing_rest_window') }}
  validates :rest_duration, presence: {if: :rest_start?, message: lambda { |*_| I18n.t('activerecord.errors.models.vehicle_usage_set.missing_rest_duration') }}

  validates_time :service_time_start, if: :service_time_start
  validates_time :service_time_end, if: :service_time_end

  after_initialize :assign_defaults, if: :new_record?
  before_validation :nilify_times
  before_save :set_stores
  before_update :update_out_of_date

  amoeba do
    exclude_association :plannings

    customize(lambda { |_original, copy|
      def copy.assign_defaults; end
      def copy.nilify_times; end
      def copy.set_stores; end
      def copy.update_out_of_date; end
      copy.vehicle_usages.each{ |vehicle_usage|
        vehicle_usage.vehicle_usage_set = copy
      }
    })
  end

  def duplicate
    copy = self.amoeba_dup
    copy.name += " (%s)" % [I18n.l(Time.zone.now, format: :long)]
    copy
  end

  private

  def set_stores
    if customer
      self.store_start = customer.stores[0] unless store_start
    end
  end

  def create_vehicle_usages
    if customer
      customer.vehicles.each { |vehicle|
        # if vehicle is not yet saved, vehicle_usage will be created in vehicle callback
        if vehicle.id
          vehicle_usages.build(vehicle: vehicle)
        end
      }
    end
  end

  def assign_defaults
    set_stores
    self.open ||= Time.utc(2000, 1, 1, 8, 0) unless open
    self.close ||= Time.utc(2000, 1, 1, 12, 0) unless close
    create_vehicle_usages
  end

  def nilify_times
    assign_attributes(rest_duration: nil) if rest_duration.eql?(Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
    assign_attributes(service_time_start: nil) if service_time_start.eql?(Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
    assign_attributes(service_time_end: nil) if service_time_end.eql?(Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
  end

  def update_out_of_date
    if rest_duration_changed?
      vehicle_usages.each{ |vehicle_usage|
        vehicle_usage.update_rest
      }
    end

    if open_changed? || close_changed? || store_start_id_changed? || store_stop_id_changed? || rest_start_changed? || rest_stop_changed? ||
      rest_duration_changed? || store_rest_id_changed? || service_time_start_changed? || service_time_end_changed?
      vehicle_usages.each{ |vehicle_usage|
        if (open_changed? && vehicle_usage.default_open == open) ||
          (close_changed? && vehicle_usage.default_close == close) ||

          (store_start_id_changed? && vehicle_usage.default_store_start == store_start) ||
          (store_stop_id_changed? && vehicle_usage.default_store_stop == store_stop) ||

          (rest_start_changed? && vehicle_usage.default_rest_start == rest_start) ||
          (rest_stop_changed? && vehicle_usage.default_rest_stop == rest_stop) ||

          (rest_duration_changed? && vehicle_usage.default_rest_duration == rest_duration) ||

          (store_rest_id_changed? && vehicle_usage.default_store_rest == store_rest) ||

          (service_time_start_changed? && vehicle_usage.default_service_time_start == service_time_start) ||
          (service_time_end_changed? && vehicle_usage.default_service_time_end == service_time_end)

          vehicle_usage.routes.each{ |route|
            route.out_of_date = true
          }
        end
      }
    end
  end

  def destroy_vehicle_usage_set
    default = customer.vehicle_usage_sets.find{ |vehicle_usage_set| vehicle_usage_set != self && !vehicle_usage_set.destroyed? }
    if !default
      errors[:base] << I18n.t('activerecord.errors.models.vehicle_usage_set.at_least_one')
      return false
    else
      customer.plannings.select{ |planning| planning.vehicle_usage_set == self }.each{ |planning|
        planning.vehicle_usage_set = default
        planning.save!
      }
    end
  end
end
