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
class Vehicle < ActiveRecord::Base
  belongs_to :customer
  belongs_to :router
  has_many :vehicle_usages, inverse_of: :vehicle, dependent: :destroy, autosave: true
  has_many :zones, inverse_of: :vehicle, dependent: :nullify, autosave: true
  enum router_dimension: Router::DIMENSION

  nilify_blanks
  auto_strip_attributes :name, :tomtom_id, :masternaut_ref
  validates :customer, presence: true
  validates :name, presence: true
  validates :emission, numericality: {only_float: true}, allow_nil: true
  validates :consumption, numericality: {only_float: true}, allow_nil: true
  validates :capacity1_1, numericality: {only_integer: true}, allow_nil: true
  validates :capacity1_2, numericality: {only_integer: true}, allow_nil: true
  validates :color, presence: true
  validates_format_of :color, with: /\A(\#[A-Fa-f0-9]{6})\Z/
  validates :speed_multiplicator, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 1.5 }, if: :speed_multiplicator
  validates :contact_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true

  after_initialize :assign_defaults, :increment_max_vehicles, if: 'new_record?'
  before_create :create_vehicle_usage
  before_update :update_out_of_date
  before_destroy :destroy_vehicle

  include RefSanitizer

  include LocalizedAttr

  attr_localized :emission, :consumption, :capacity1_1, :capacity1_2

  def self.emissions_table
    [
      [I18n.t('vehicles.emissions_nothing', n: 0), '0.0'],
      [I18n.t('vehicles.emissions_light_petrol', n: self.localize_numeric_value(2.71)), '2.71'],
      [I18n.t('vehicles.emissions_light_diesel', n: self.localize_numeric_value(3.07)), '3.07'],
      [I18n.t('vehicles.emissions_light_lgp', n: self.localize_numeric_value(1.77)), '1.77'],
    ]
  end

  amoeba do
    exclude_association :vehicle_usages
    exclude_association :zones

    customize(lambda { |_original, copy|
      def copy.assign_defaults; end
      def copy.increment_max_vehicles; end
      def copy.create_vehicle_usage; end
      def copy.update_out_of_date; end
      def copy.destroy_vehicle; end
    })
  end

  def default_router
    router || customer.router
  end

  def default_router_dimension
    router_dimension || customer.router_dimension
  end

  def default_speed_multiplicator
    customer.speed_multiplicator * (speed_multiplicator || 1)
  end

  def available_position?
    (!tomtom_id.blank? && customer.tomtom?) || (!teksat_id.blank? && customer.teksat?) || (!orange_id.blank? && customer.orange?)
  end

  def capacity_changed?
    capacity1_1_changed? || capacity1_2_changed?
  end

  private

  def assign_defaults
    self.color ||= COLORS_TABLE[0]
  end

  def increment_max_vehicles
    customer.max_vehicles += 1
  end

  def create_vehicle_usage
    h = {}
    customer.vehicle_usage_sets.each{ |vehicle_usage_set|
      u = vehicle_usage_set.vehicle_usages.build(vehicle: self)
      h[vehicle_usage_set] = u
      vehicle_usages << u
    }
    customer.plannings.each{ |planning|
      planning.vehicle_usage_add(h[planning.vehicle_usage_set])
    }
  end

  def update_out_of_date
    if emission_changed? || consumption_changed? || capacity_changed? || router_id_changed? || router_dimension_changed? || speed_multiplicator_changed?
      vehicle_usages.each{ |vehicle_usage|
        vehicle_usage.routes.each{ |route|
          route.out_of_date = true
          route.optimized_at = nil
        }
      }
    end
  end

  def destroy_vehicle
    default = customer.vehicles.find{ |vehicle| vehicle != self && !vehicle.destroyed? }
    if !default
      errors[:base] << I18n.t('activerecord.errors.models.vehicles.at_least_one')
      false
    end
  end
end
