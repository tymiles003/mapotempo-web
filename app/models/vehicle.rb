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
class CapacitiesValidator < ActiveModel::Validator
  def validate(record)
    !record.capacities || record.capacities.values.each{ |q| !q || Float(q) }
  rescue
    record.errors[:capacities] << I18n.t('activerecord.errors.models.vehicle.attributes.capacities.not_float')
  end
end

class Vehicle < ActiveRecord::Base
  belongs_to :customer
  belongs_to :router
  has_many :vehicle_usages, inverse_of: :vehicle, dependent: :destroy, autosave: true
  has_many :zones, inverse_of: :vehicle, dependent: :nullify, autosave: true
  enum router_dimension: Router::DIMENSION
  serialize :capacities, DeliverableUnitQuantity

  include HashBoolAttr
  store_accessor :router_options, :time, :distance, :avoid_zones, :isochrone, :isodistance, :motorway, :toll, :trailers, :weight, :weight_per_axle, :height, :width, :length, :hazardous_goods
  hash_bool_attr :router_options, :time, :distance, :avoid_zones, :isochrone, :isodistance, :motorway, :toll

  nilify_blanks
  auto_strip_attributes :name
  validates :customer, presence: true
  validates :name, presence: true
  validates :emission, numericality: {only_float: true}, allow_nil: true
  validates :consumption, numericality: {only_float: true}, allow_nil: true
  validates :color, presence: true
  validates_format_of :color, with: /\A(\#[A-Fa-f0-9]{6})\Z/
  validates :speed_multiplicator, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 1.5 }, if: :speed_multiplicator
  validates :contact_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true
  validates_with CapacitiesValidator, fields: [:capacities]

  after_initialize :assign_defaults, :increment_max_vehicles, if: 'new_record?'
  before_create :create_vehicle_usage
  before_save :nilify_router_options_blanks
  before_update :update_out_of_date
  before_destroy :destroy_vehicle

  include RefSanitizer

  include LocalizedAttr

  attr_localized :emission, :consumption, :capacities

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

  def devices
    if self[:devices].respond_to?('deep_symbolize_keys!')
      self[:devices].deep_symbolize_keys!
    else
      self[:devices]
    end
  end

  def default_router
    self.router || customer.router
  end

  def default_router_dimension
    self.router_dimension || customer.router_dimension
  end

  def default_router_options
    default_router.options.select{ |k, v| ValueToBoolean.value_to_boolean(v) }.each do |key, value|
      @current_router_options ||= {}
      @current_router_options[key.to_s] = router_options[key.to_s] || customer.router_options[key.to_s]
    end if !@current_router_options

    @current_router_options ||= {}
  end

  def default_speed_multiplicator
    customer.speed_multiplicator * (speed_multiplicator || 1)
  end

  def default_capacities
    @default_capacities ||= Hash[customer.deliverable_units.collect{ |du|
      [du.id, capacities && capacities[du.id] ? capacities[du.id] : du.default_capacity]
    }]
    @default_capacities
  end

  def default_capacities?
    default_capacities && default_capacities.values.any?{ |q| q && q > 0 }
  end

  def capacities?
    capacities && capacities.values.any?{ |q| q }
  end

  def capacities_changed?
    capacities ? capacities.any?{ |i, q|
      !capacities_was || q != capacities_was[i]
    } : !!capacities_was
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

  def nilify_router_options_blanks
    true_options = default_router.options.select { |o, v| v == 'true' }.keys
    write_attribute :router_options, self.router_options.delete_if { |k, v| v.to_s.empty? || true_options.exclude?(k) }
  end

  def update_out_of_date
    if emission_changed? || consumption_changed? || capacities_changed? || router_id_changed? || router_dimension_changed? || router_options_changed? || speed_multiplicator_changed?
      vehicle_usages.each{ |vehicle_usage|
        vehicle_usage.routes.each{ |route|
          route.out_of_date = true
          route.optimized_at = route.last_sent_to = route.last_sent_at = nil
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
