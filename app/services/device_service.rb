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
class DeviceService
  attr_reader :customer, :service_name, :cache_object, :service

  def initialize(params)
    @customer = params[:customer]
    @cache_object = Mapotempo::Application.config.devices.cache_object
    @service_name = self.class.name.gsub('Service', '').downcase.to_sym
    @service = Mapotempo::Application.config.devices[service_name]
  end

  def send_route(route, options = {})
    service.send_route customer, route, options
    route.update! last_sent_at: Time.now.utc
    route.last_sent_at
  end

  def clear_route(route)
    service.clear_route customer, route
    route.update! last_sent_at: nil
  end

  private

  def with_cache(key, &block)
    result = cache_object.read key
    return result if result

    result = yield
    cache_object.write key, result
    result
  end
end
