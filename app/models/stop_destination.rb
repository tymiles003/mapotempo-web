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
class StopDestination < Stop
  belongs_to :destination

  validates :destination, presence: true

  def order
    planning = route.planning
    if planning.customer.enable_orders && planning.order_array && planning.date
      planning.order_array.orders.where(destination_id: destination.id, shift: planning.date - planning.order_array.base_date).first
    end
  end

  def position?
    !destination.lat.nil? && !destination.lng.nil?
  end

  def position
    destination
  end

  def lat
    destination.lat
  end

  def lng
    destination.lng
  end

  def open
    destination.open
  end

  def close
    destination.close
  end

  def duration
    to = destination.take_over ? destination.take_over : destination.customer.take_over
    to ? to.seconds_since_midnight : 0
  end

  def base_id
    "d#{destination.id}"
  end

  def base_updated_at
    destination.updated_at
  end

  def ref
    destination.ref
  end

  def name
    destination.name
  end

  def street
    destination.street
  end

  def postalcode
    destination.postalcode
  end

  def city
    destination.city
  end

  def country
    destination.country
  end

  def detail
    destination.detail
  end

  def comment
    destination.comment
  end

  def phone_number
    destination.phone_number
  end

  def to_s
    "#{active ? 'x' : '_'} #{destination.name}"
  end
end
