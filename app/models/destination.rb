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
require 'geocode'

class Destination < ActiveRecord::Base
  belongs_to :customer
  has_many :stops, inverse_of: :destination, dependent: :delete_all
  has_many :orders, inverse_of: :destination, dependent: :delete_all
  has_and_belongs_to_many :tags, after_add: :update_tags_track, after_remove: :update_tags_track

  nilify_blanks
  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
#  validates :city, presence: true
#  validates :lat, numericality: {only_float: true} # maybe nil
#  validates :lng, numericality: {only_float: true} # maybe nil

  before_save :update_tags, :create_orders
  before_update :update_geocode, :update_out_of_date

  def geocode
    address = Geocode.code(street, postalcode, city)
    Rails.logger.info address
    if address
      self.lat, self.lng, self.geocoding_accuracy = address[:lat], address[:lng], address[:accuracy]
    end
    @is_gecoded = true
  end

  def distance(position)
    lat && lng && position.lat && position.lng && Math.hypot(position.lat - lat, position.lng - lng)
  end

  def destroy
    # Too late to do this in before_destroy callback, children already destroyed
    Route.transaction do
      stops.each{ |stop|
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

  def update_geocode
    if !@is_gecoded && (lat_changed? || lng_changed?)
      self.geocoding_accuracy = nil
    end
    if !@is_gecoded && (street_changed? || postalcode_changed? || city_changed?)
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
      stops.each{ |stop|
        stop.route.out_of_date = true
        stop.route.save
      }
    end
  end
end
