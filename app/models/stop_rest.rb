# Copyright © Mapotempo, 2015
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
class StopRest < Stop
  def position?
    !route.vehicle_usage.default_store_rest.nil? && !route.vehicle_usage.default_store_rest.lat.nil? && !route.vehicle_usage.default_store_rest.lng.nil?
  end

  def position
    route.vehicle_usage.default_store_rest
  end

  def lat
    if position?
      route.vehicle_usage.default_store_rest.lat
    end
  end

  def lng
    if position?
      route.vehicle_usage.default_store_rest.lng
    end
  end

  def open1
    route.vehicle_usage.default_rest_start
  end

  def close1
    route.vehicle_usage.default_rest_stop
  end

  def open2
    nil
  end

  def close2
    nil
  end

  def duration
    to = route.vehicle_usage.default_rest_duration
    to ? to.seconds_since_midnight : 0
  end

  def base_id
    "r#{route.vehicle_usage.id}"
  end

  def base_updated_at
    route.vehicle_usage.updated_at
  end

  def ref
    nil
  end

  def name
    if position?
      route.vehicle_usage.default_store_rest.name
    else
      I18n.t('stops.default.name_rest')
    end
  end

  def street
    if position?
      route.vehicle_usage.default_store_rest.street
    end
  end

  def postalcode
    if position?
      route.vehicle_usage.default_store_rest.postalcode
    end
  end

  def city
    if position?
      route.vehicle_usage.default_store_rest.city
    end
  end

  def country
    if position?
      route.vehicle_usage.default_store_rest.country
    end
  end

  def detail
    nil
  end

  def comment
    nil
  end

  def phone_number
    nil
  end

  def to_s
    "#{active ? 'x' : '_'} [Rest]"
  end
end
