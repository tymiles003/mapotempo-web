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
class LocalizationDestinationValidator < ActiveModel::Validator
  def validate(record)
    if record.postalcode.nil? && record.city.nil? && (record.lat.nil? || record.lng.nil?)
      record.errors[:base] << I18n.t('activerecord.errors.models.destination.missing_address_or_latlng')
    end
  end
end

class Destination < ActiveRecord::Base
  belongs_to :customer
  has_many :visits, inverse_of: :destination, dependent: :destroy, autosave: true
  accepts_nested_attributes_for :visits, allow_destroy: true
  validates_associated_bubbling :visits
  enum geocoding_level: {point: 1, house: 2, intersection: 3, street: 4, city: 5}

  nilify_blanks
  auto_strip_attributes :name, :street, :postalcode, :city, :country, :detail, :comment, :phone_number
  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
#  validates :city, presence: true
  validates :lat, numericality: {only_float: true}, allow_nil: true
  validates :lng, numericality: {only_float: true}, allow_nil: true
  validates_inclusion_of :lat, in: -90..90, allow_nil: true, message: I18n.t('activerecord.errors.models.destination.lat_outside_range')
  validates_inclusion_of :lng, in: -180..180, allow_nil: true, message: I18n.t('activerecord.errors.models.destination.lng_outside_range')
  validates_inclusion_of :geocoding_accuracy, in: 0..1, allow_nil: true, message: I18n.t('activerecord.errors.models.destination.geocoding_accuracy_outside_range')
  validates_with LocalizationDestinationValidator, fields: [:street, :city, :lat, :lng]

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

  def delay_geocode
    @is_gecoded = true
  end

  def distance(position)
    lat && lng && position.lat && position.lng && Math.hypot(position.lat - lat, position.lng - lng)
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
      visits.each{ |visit|
        visit.out_of_date
      }
    end
  end
end
