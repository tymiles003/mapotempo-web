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
  belongs_to :zoning, touch: true
  has_and_belongs_to_many :vehicles

  validate :valide_vehicles_from_customer

  def inside?(lat, lng)
    point = RGeo::Cartesian.factory.point(lng, lat)
    (@geom || decode_geom).geometry().contains?(point)
  end

  private
    def decode_geom
      @geom = RGeo::GeoJSON.decode(polygon, :json_parser => :json)
    end

    def valide_vehicles_from_customer
      vehicles.each { |vehicle|
        if vehicle.customer != zoning.customer
          errors.add(:vehicles, :bad_customer)
          return
        end
      }
    end
end
