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
class GeocoderJob < Struct.new(:customer_id, :planning_id)
  def perform
    customer = Customer.find(customer_id)
    Delayed::Worker.logger.info "GeocoderJob customer_id=#{customer_id} perform"
    count = Destination.where(customer_id: customer_id, lat: nil).count
    i = 0
    Destination.where(customer_id: customer_id, lat: nil).each_slice(50){ |destinations|
      Destination.transaction do
        destinations.each { |destination|
          begin
            destination.geocode
          rescue StandardError => e
          end
          Delayed::Worker.logger.info destination.inspect
          destination.save
          i += 1
        }
        customer.job_geocoding.progress = Integer(i * 100 / count)
        customer.job_geocoding.save
        Delayed::Worker.logger.info "GeocoderJob customer_id=#{customer_id} #{customer.job_geocoding.progress}%"
      end
    }

    Destination.transaction do
      if planning_id
        planning = Planning.where(customer_id: customer_id, id: planning_id).first
        if planning
          planning.compute
          planning.save
        end
      end
    end
  end
end
