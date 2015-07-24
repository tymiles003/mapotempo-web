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
class GeocoderStoresJob < Struct.new(:customer_id)

  def before(job)
    @job = job
  end

  def perform
    customer = Customer.find(customer_id)
    Delayed::Worker.logger.info "GeocoderStoresJob customer_id=#{customer_id} perform"
    count = customer.stores.where(lat: nil).count
    i = 0
    customer.stores.where(lat: nil).each_slice(50){ |stores|
      Store.transaction do
        stores.each { |store|
          begin
            store.geocode
          rescue
          end
          Delayed::Worker.logger.info store.inspect
          store.save
          i += 1
        }
        @job.progress = Integer(i * 100 / count).to_s
        @job.save
        Delayed::Worker.logger.info "GeocoderStoresJob customer_id=#{customer_id} #{@job.progress}%"
      end
    }
  end
end
