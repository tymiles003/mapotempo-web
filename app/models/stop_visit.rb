# Copyright © Mapotempo, 2015-2016
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
class StopVisit < Stop
  delegate :lat, :lng, :open1, :close1, :open2, :close2, :name, :street, :postalcode, :city, :country, :detail, :comment, :phone_number, :color, :icon, :default_icon, :default_icon_size, to: :visit

  validates :visit, presence: true

  def ref
    visit.ref || visit.destination.ref
  end

  def order
    planning = route.planning
    if planning.customer.enable_orders && planning.order_array && planning.date
      planning.order_array.orders.where(visit_id: visit.id, shift: planning.date - planning.order_array.base_date).first
    end
  end

  def position?
    !visit.destination.lat.nil? && !visit.destination.lng.nil?
  end

  def position
    visit.destination
  end

  def duration
    to = visit.take_over || visit.destination.customer.take_over
    to ? to.seconds_since_midnight : 0
  end

  def base_id
    "d#{visit.id}"
  end

  def base_updated_at
    [visit.updated_at, visit.destination.updated_at].max
  end

  def icon_size
    nil
  end

  def default_color
    visit.color || route.default_color
  end

  def to_s
    "#{active ? 'x' : '_'} #{visit.destination.name}"
  end
end
