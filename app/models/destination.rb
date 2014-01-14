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
  has_many :stops, dependent: :destroy
  has_and_belongs_to_many :tags, after_add: :update_add_tag, after_remove: :update_remove_tag

#  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
  validates :city, presence: true
#  validates :lat, presence: true, numericality: {only_float: true}
#  validates :lng, presence: true, numericality: {only_float: true}

  before_update :update_out_of_date, :update_geocode
  before_destroy :destroy_out_of_date

  def geocode
    address = Geocode.code(street, postalcode, city)
    Rails.logger.info address
    if address
      self.lat, self.lng = address[:lat], address[:lng]
    end
    is_gecoded = true
  end

  def reverse_geocode
    address = Geocode.reverse(lat, lng)
    self.street, self.postalcode, self.city = address[:street], address[:postal_code], address[:city]
    is_gecoded = true
  end

  private
    attr_accessor :is_gecoded

    def update_out_of_date
      if lat_changed? or lng_changed? or open_changed? or close_changed? or quantity_changed?
        out_of_date
      end
    end

    def update_geocode
      if !is_gecoded and (street_changed? or postalcode_changed? or city_changed?)
        geocode
      end
    end

    def update_add_tag(tag)
      customer.plannings.select{ |planning|
        planning.tags.include?(tag)
      }.each{ |planning|
        planning.destination_add(self)
      }
    end

    def update_remove_tag(tag)
      customer.plannings.select{ |planning|
        planning.tags.include?(tag)
      }.each{ |planning|
        planning.destination_remove(self)
      }
    end

    def destroy_out_of_date
      out_of_date
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
