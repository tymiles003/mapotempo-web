# Copyright © Mapotempo, 2016
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
class TomtomService < DeviceService
  def test_list(params)
    service.test_list customer, params
  end

  def list_devices
    with_cache [:list_devices, service_name, customer.id, customer.tomtom_user] do
      service.list_devices customer
    end
  end

  def get_vehicles_pos
    with_cache [:get_vehicles_pos, service_name, customer.id, customer.tomtom_user] do
      service.get_vehicles_pos customer
    end
  end

  def list_vehicles(params)
    with_cache [:list_vehicles, service_name, customer.id, customer.tomtom_user] do
      service.list_vehicles customer, params
    end
  end

  def list_addresses
    with_cache [:list_addresses, service_name, customer.id, customer.tomtom_user] do
      service.list_addresses customer
    end
  end
end
