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
  validates :store_stop, presence: true
  validates :name, presence: true
  validates_time :open, presence: true
  validates_time :close, presence: true, after: :open
  validates_time :rest_start, if: :rest_start
  validates_time :rest_stop, on_or_after: :rest_start, if: :rest_stop

  after_initialize :assign_defaults, if: 'new_record?'
  before_save :set_stores
  before_update :update_out_of_date

  amoeba do
    exclude_association :plannings

    customize(lambda { |_original, copy|
      copy.vehicle_usages.each{ |vehicle_usage|
        vehicle_usage.vehicle_usage_set = copy
      }
    })

    append name: Time.now.strftime(' %Y-%m-%d %H:%M')
  end

  private

  def set_stores
    if customer
      self.store_start = customer.stores[0] unless store_start
    end
    self.store_stop = store_start unless store_stop
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
    self.open = Time.utc(2000, 1, 1, 8, 0) unless open
    self.close = Time.utc(2000, 1, 1, 12, 0) unless close
    create_vehicle_usages
  end

  def update_out_of_date
    if rest_duration_changed?
      if rest_duration.nil?
        # No more rest
        routes.each{ |route|
          route.stops.select{ |stop| stop.is_a?(StopRest) }.each{ |stop|
            route.remove_stop(stop)
          }
        }
      elsif rest_duration_was.nil?
        # New rest
        routes.each{ |route|
          route.add_rest
        }
      end
    end

    if open_changed? || close_changed? || store_start_id_changed? || store_stop_id_changed? || rest_start_changed? || rest_stop_changed? || rest_duration_changed? || store_rest_id_changed?
      vehicle_usages.each{ |vehicle_usage|
        if (open_changed? && vehicle_usage.default_open == open) || (close_changed? && vehicle_usage.default_close == close) || (store_start_id_changed? && vehicle_usage.default_store_start.id == store_start_id) ||
          (store_stop_id_changed? && vehicle_usage.default_store_stop.id == store_stop_id) || (rest_start_changed? && vehicle_usage.default_rest_start == rest_start) || (rest_stop_changed? && vehicle_usage.default_rest_stop == rest_stop) ||
          (rest_duration_changed? && vehicle_usage.default_rest_duration == rest_duration) || (store_rest_id_changed? && vehicle_usage.default_store_rest.id == store_rest)
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
      raise I18n.t('activerecord.errors.models.vehicle_usage_sets.at_least_one')
    else
      customer.plannings.select{ |planning| planning.vehicle_usage_set == self }.each{ |planning|
        planning.vehicle_usage_set = default
        planning.save!
      }
    end
  end
end
