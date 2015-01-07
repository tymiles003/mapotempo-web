# Copyright © Mapotempo, 2014
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
class OrderArray < ActiveRecord::Base
  belongs_to :customer
  has_many :orders, -> {includes :products}, inverse_of: :order_array, :autosave => true, :dependent => :destroy
  has_many :planning, inverse_of: :order_array, :dependent => :nullify
  enum length: {week: 7, week2: 14, month: 31}

  nilify_blanks
  validates :customer, presence: true
  validates :name, presence: true
  validates :base_date, presence: true
  validates :length, presence: true

  amoeba do
    enable
    exclude_field :planning

    customize(lambda { |original, copy|
      copy.orders.each{ |order|
        order.order_array = copy
      }
    })

    append :name => Time.now.strftime(" %Y-%m-%d %H:%M")
  end

  def days
    length = !base_date ? 0 : week? ? 7 : week2? ? 14 : ((base_date >> 1) - base_date).numerator
  end

  def default_orders
    customer.destinations.each{ |destination|
      add_destination(destination)
    }
  end

  def destinations_orders
    self.orders.joins(:products)
    self.orders.group_by(&:destination_id).values.sort_by{ |destination_orders|
      destination_orders[0].destination.name
    }.collect{ |destination_orders|
      destination_orders.sort_by(&:shift)
    }
  end

  def add_destination(destination)
    days.times{ |i|
      orders.build(shift: i, destination: destination)
    }
  end

  private

end
