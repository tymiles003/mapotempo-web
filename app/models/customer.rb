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
require 'sanitize'

class Customer < ActiveRecord::Base
  belongs_to :reseller
  belongs_to :profile
  belongs_to :router
  belongs_to :job_destination_geocoding, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  belongs_to :job_store_geocoding, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  belongs_to :job_optimizer, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  has_many :order_arrays, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :products, -> { order('code') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :plannings, -> { includes(:tags).order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :zonings, inverse_of: :customer, dependent: :delete_all
  before_destroy :destroy_disable_vehicle_usage_sets_validation # Declare and run before has_many :vehicle_usage_sets
  has_many :vehicle_usage_sets, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :destroy
  has_many :vehicles, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :stores, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :destinations, -> { includes(:tags).order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :tags, -> { order('label') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :users, inverse_of: :customer, dependent: :nullify

  nilify_blanks
  auto_strip_attributes :name, :tomtom_account, :tomtom_user, :tomtom_password, :print_header, :masternaut_user, :masternaut_password, :alyacom_association, :default_country
  validates :profile, presence: true
  validates :router, presence: true
  validates :name, presence: true
  validates :default_country, presence: true
  validates :stores, length: { maximum: Mapotempo::Application.config.max_destinations / 10, message: :over_max_limit }
  validates :destinations, length: { maximum: Mapotempo::Application.config.max_destinations, message: :over_max_limit }
  validates :optimization_cluster_size, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_vehicles, numericality: { greater_than: 0 }
  validate do
    errors.add(:max_vehicles, :not_an_integer) if @invalid_max_vehicle
    !@invalid_max_vehicle
  end
  validates :speed_multiplicator, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 1.5 }, if: :speed_multiplicator

  after_initialize :assign_defaults, :update_max_vehicles, if: 'new_record?'
  after_create :create_default_store, :create_default_vehicle_usage_set
  before_update :update_out_of_date, :update_max_vehicles
  before_save :sanitize_print_header

  def destinations_destroy_all
    destinations.destroy_all
    plannings.each{ |planning|
      planning.routes.each{ |route|
        route.out_of_date = true
        route.force_reindex
      }
    }
  end

  def default_position
    store = stores.find{ |s| !s.lat.nil? && !s.lng.nil? }
    # store ? [store.lat, store.lng] : [I18n.t('stores.default.lat'), I18n.t('stores.default.lng')]
    {lat: store ? store.lat : I18n.t('stores.default.lat'), lng: store ? store.lng : I18n.t('stores.default.lng')}
  end

  def max_vehicles
    @max_vehicles = @max_vehicles || vehicles.size
  end

  def max_vehicles=(max)
    begin
      if !max.blank?
        @max_vehicles = Integer(max.to_s, 10)
      end
    rescue ArgumentError
      @invalid_max_vehicle = true
    end
  end

  def tomtom?
    enable_tomtom && !tomtom_account.blank? && !tomtom_user.blank? && !tomtom_password.blank?
  end

  private

  def assign_defaults
    default_country ||= I18n.t('customers.default.country')
  end

  def create_default_store
    stores.create(
      name: I18n.t('stores.default.name'),
      city: I18n.t('stores.default.city'),
      lat: Float(I18n.t('stores.default.lat')),
      lng: Float(I18n.t('stores.default.lng'))
    )
  end

  def create_default_vehicle_usage_set
    vehicle_usage_sets.create(
      name: I18n.t('vehicle_usage_sets.default.name'),
      store_start: stores[0],
      store_stop: stores[0]
    )
  end

  def update_out_of_date
    if take_over_changed? || router_id_changed? || speed_multiplicator_changed?
      Route.transaction do
        plannings.each{ |planning|
          planning.routes.each{ |route|
            route.out_of_date = true
          }
        }
      end
    end
  end

  def update_max_vehicles
    if max_vehicles != vehicles.size
      if vehicles.size < max_vehicles
        # Add new
        (max_vehicles - vehicles.size).times{ |_i|
          vehicle = vehicles.build(name: I18n.t('vehicles.default_name', n: vehicles.size + 1))
          vehicle.color = Vehicle.colors_table[(vehicles.size - 1) % Vehicle.colors_table.size]
        }
      elsif vehicles.size > max_vehicles
        # Delete
        (vehicles.size - max_vehicles).times{ |i|
          vehicle = vehicles[vehicles.size - 1]
          vehicles.destroy(vehicle)
        }
      end
      @max_vehicles = vehicles.size
    end
  end

  def sanitize_print_header
    self.print_header = Sanitize.fragment(print_header, Sanitize::Config::RELAXED)
  end

  def destroy_disable_vehicle_usage_sets_validation
    vehicle_usage_sets.each{ |vehicle_usage_set|
      def vehicle_usage_set.destroy_vehicle_usage_set
        # Avoid validation of at least one vehicle_usage_set by customer
      end
    }
  end
end
