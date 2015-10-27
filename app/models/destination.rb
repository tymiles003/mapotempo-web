# Copyright © Mapotempo, 2013-2014
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
class LocalizationDestinationValidator < ActiveModel::Validator
  def validate(record)
    if record.postalcode.nil? && record.city.nil? && (record.lat.nil? || record.lng.nil?)
      record.errors[:base] << I18n.t('activerecord.errors.models.destination.missing_address_or_latlng')
    end
  end
end

class Destination < ActiveRecord::Base
  belongs_to :customer
  has_many :stop_destinations, inverse_of: :destination, dependent: :delete_all
  has_many :orders, inverse_of: :destination, dependent: :delete_all
  has_and_belongs_to_many :tags, after_add: :update_tags_track, after_remove: :update_tags_track
  enum geocoding_level: {point: 1, house: 2, intersection: 3, street: 4, city: 5}

  nilify_blanks
  auto_strip_attributes :name, :street, :postalcode, :city, :country, :detail, :comment, :phone_number, :ref
  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
#  validates :city, presence: true
  validates :lat, numericality: {only_float: true}, :allow_nil => true
  validates :lng, numericality: {only_float: true}, :allow_nil => true
  validates_inclusion_of :lat, in: -90..90, :allow_nil => true, message: I18n.t('activerecord.errors.models.destination.lat_outside_range')
  validates_inclusion_of :lng, in: -180..180, :allow_nil => true, message: I18n.t('activerecord.errors.models.destination.lng_outside_range')
  validates_inclusion_of :geocoding_accuracy, in: 0..1, :allow_nil => true, message: I18n.t('activerecord.errors.models.destination.geocoding_accuracy_outside_range')
  validates_with LocalizationDestinationValidator, fields: [:street, :city, :lat, :lng]
  validates_time :open, if: :open
  validates_time :close, presence: false, after: :open, if: :close

  before_save :update_tags, :create_orders
  before_create :create_geocode
  before_update :update_geocode, :update_out_of_date

  def geocode
    address = Mapotempo::Application.config.geocode_geocoder.code(street, postalcode, city, !country.nil? && !country.empty? ? country : customer.default_country)
    Rails.logger.info 'geocode: ' + address.inspect
    if address
      self.lat, self.lng, self.geocoding_accuracy, self.geocoding_level = address[:lat], address[:lng], address[:accuracy], address[:quality]
    else
      self.lat = self.lng = self.geocoding_accuracy = self.geocoding_level = nil
    end
    @is_gecoded = true
  end

  def distance(position)
    lat && lng && position.lat && position.lng && Math.hypot(position.lat - lat, position.lng - lng)
  end

  def destroy
    # Too late to do this in before_destroy callback, children already destroyed
    Route.transaction do
      stop_destinations.each{ |stop|
        stop.route.remove_stop(stop)
        stop.route.save
      }
    end
    super
  end

  private

  def update_out_of_date
    if lat_changed? || lng_changed? || open_changed? || close_changed? || quantity_changed? || take_over_changed?
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

  def update_tags_track(_tag)
    @tags_updated = true
  end

  def update_tags
    if customer && (@tags_updated || new_record?)
      @tags_updated = false

      # Don't use local collection here, not set when save new record
      customer.plannings.each{ |planning|
        if planning.destinations.include?(self)
          if planning.tags.to_a & tags.to_a != planning.tags.to_a
            planning.destination_remove(self)
          end
        else
          if planning.tags.to_a & tags.to_a == planning.tags.to_a
            planning.destination_add(self)
          end
        end
      }
    end

    true
  end

  def create_orders
    if customer && new_record?
      customer.order_arrays.each{ |order_array|
        order_array.add_destination(self)
      }
    end
  end

  def out_of_date
    Route.transaction do
      stop_destinations.each{ |stop|
        stop.route.out_of_date = true
        stop.route.save
      }
    end
  end
end
