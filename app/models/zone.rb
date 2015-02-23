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
class Zone < ActiveRecord::Base
  belongs_to :zoning, inverse_of: :zones
  belongs_to :vehicle, inverse_of: :zones

  nilify_blanks
  validates :polygon, presence: true
  validate :valide_vehicle_from_customer

  before_save :update_out_of_date

  amoeba do
    enable
  end

  def inside?(lat, lng)
    if !lat.nil? && !lng.nil?
      point = RGeo::Cartesian.factory.point(lng, lat)
      (@geom || decode_geom).geometry().contains?(point)
    end
  end

  private
    def decode_geom
      @geom = RGeo::GeoJSON.decode(polygon, :json_parser => :json)
    end

    def valide_vehicle_from_customer
      if vehicle && vehicle.customer != zoning.customer
        errors.add(:vehicle, :bad_customer)
        false
      else
        true
      end
    end

    def update_out_of_date
      if self.changed?
        zoning.flag_out_of_date
      end
    end
end
