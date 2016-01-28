# Copyright © Mapotempo, 2014-2015
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
require 'font_awesome'

class LocalizationStoreValidator < ActiveModel::Validator
  def validate(record)
    if record.postalcode.nil? && record.city.nil? && (record.lat.nil? || record.lng.nil?)
      record.errors[:base] << I18n.t('activerecord.errors.models.store.missing_address_or_latlng')
    end
  end
end

class Store < ActiveRecord::Base
  belongs_to :customer
  has_many :vehicle_usage_set_starts, class_name: 'VehicleUsageSet', inverse_of: :store_start, foreign_key: 'store_start_id'
  has_many :vehicle_usage_set_stops, class_name: 'VehicleUsageSet', inverse_of: :store_stop, foreign_key: 'store_stop_id'
  has_many :vehicle_usage_set_rests, class_name: 'VehicleUsageSet', inverse_of: :store_rest, foreign_key: 'store_rest_id', dependent: :nullify
  has_many :vehicle_usage_starts, class_name: 'VehicleUsage', inverse_of: :store_start, foreign_key: 'store_start_id', dependent: :nullify
  has_many :vehicle_usage_stops, class_name: 'VehicleUsage', inverse_of: :store_stop, foreign_key: 'store_stop_id', dependent: :nullify
  has_many :vehicle_usage_rests, class_name: 'VehicleUsage', inverse_of: :store_rest, foreign_key: 'store_rest_id', dependent: :nullify
  enum geocoding_level: {point: 1, house: 2, intersection: 3, street: 4, city: 5}

  nilify_blanks
  auto_strip_attributes :name, :street, :postalcode, :city
  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
#  validates :city, presence: true
  validates :lat, numericality: {only_float: true}, allow_nil: true
  validates :lng, numericality: {only_float: true}, allow_nil: true
  validates_inclusion_of :lat, in: -90..90, allow_nil: true, message: I18n.t('activerecord.errors.models.store.lat_outside_range')
  validates_inclusion_of :lng, in: -180..180, allow_nil: true, message: I18n.t('activerecord.errors.models.store.lng_outside_range')
  validates_inclusion_of :geocoding_accuracy, in: 0..1, allow_nil: true, message: I18n.t('activerecord.errors.models.destination.geocoding_accuracy_outside_range')
  validates_inclusion_of :icon, in: FontAwesome::icons_table, allow_blank: true, message: I18n.t('activerecord.errors.models.store.icon_unknown')
  validates :icon_size, inclusion: { in: %w(small medium large), allow_blank: true, message: I18n.t('activerecord.errors.models.store.icon_size_invalid') }
  validates_with LocalizationStoreValidator, fields: [:street, :city, :lat, :lng]

  before_create :create_geocode
  before_update :update_geocode
  before_save :update_out_of_date
  before_destroy :destroy_vehicle_store

  def geocode
    address = Mapotempo::Application.config.geocode_geocoder.code(street, postalcode, city, !country.nil? && !country.empty? ? country : customer.default_country)
    Rails.logger.info address.inspect
    if address
      self.lat, self.lng, self.geocoding_accuracy, self.geocoding_level = address[:lat], address[:lng], address[:accuracy], address[:quality]
    else
      self.lat = self.lng = self.geocoding_accuracy = self.geocoding_level = nil
    end
    @is_gecoded = true
  end

  def delay_geocode
    @is_gecoded = true
  end

  def distance(position)
    lat && lng && position.lat && position.lng && Math.hypot(position.lat - lat, position.lng - lng)
  end

  def destroy
    out_of_date # Too late to do this in before_destroy callback, children already destroyed
    super
  end

  private

  def update_out_of_date
    if lat_changed? || lng_changed?
      out_of_date
    end
  end

  def create_geocode
    if !@is_gecoded && (lat.nil? || lng.nil?)
      geocode
    end
  end

  def update_geocode
    # when lat/lng are specified manually, geocoding_accuracy has no sense
    if !@is_gecoded && self.point? && (lat_changed? || lng_changed?)
      self.geocoding_accuracy = nil
    end
    if !lat.nil? && !lng.nil?
      @is_gecoded = true
    end
    if !@is_gecoded && (street_changed? || postalcode_changed? || city_changed? || country_changed?)
      geocode
    end
  end

  def out_of_date
    Route.transaction do
      routes_usage_set = vehicle_usage_set_starts.collect{ |vehicle_usage_set_start|
        vehicle_usage_set_start.vehicle_usages.select{ |vehicle_usage| !vehicle_usage.store_start }.collect(&:routes)
      } +
      vehicle_usage_set_stops.collect{ |vehicle_usage_set_stop|
        vehicle_usage_set_stop.vehicle_usages.select{ |vehicle_usage| !vehicle_usage.store_stop }.collect(&:routes)
      } +
      vehicle_usage_set_rests.collect{ |vehicle_usage_set_rest|
        vehicle_usage_set_rest.vehicle_usages.select{ |vehicle_usage| !vehicle_usage.store_rest }.collect(&:routes)
      }

      routes_usage = (vehicle_usage_starts + vehicle_usage_stops + vehicle_usage_rests).collect(&:routes)

      (routes_usage_set + routes_usage).flatten.uniq.each{ |route|
        route.out_of_date = true
        route.save!
      }
    end
  end

  def destroy_vehicle_store
    default = customer.stores.find{ |store| store != self && !store.destroyed? }
    if default
      vehicle_usage_set_starts.each{ |vehicle_usage_set|
        vehicle_usage_set.store_start = default
        vehicle_usage_set.save!
      }
      vehicle_usage_set_stops.each{ |vehicle_usage_set|
        vehicle_usage_set.store_stop = default
        vehicle_usage_set.save!
      }
      true
    else
      errors[:base] << I18n.t('activerecord.errors.models.store.at_least_one')
      false
    end
  end
end
