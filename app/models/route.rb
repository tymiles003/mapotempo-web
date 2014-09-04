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
require 'trace'

class Route < ActiveRecord::Base
  belongs_to :planning
  belongs_to :vehicle
  has_many :stops, inverse_of: :route, :autosave => true, :dependent => :destroy, :order=>"\"index\" ASC", :include=>:destination

  nilify_blanks
  validates :planning, presence: true
#  validates :vehicle, presence: true # nil on unplanned route

  after_initialize :assign_defaults, if: 'new_record?'

  amoeba do
    enable

    customize(lambda { |original, copy|
      copy.stops.each{ |stop|
        stop.route = copy
      }
    })
  end

  def default_stops
    i = 0
    stops.clear
    planning.destinations.each { |c|
      stops.build(destination:c, active:true, index:i+=1)
    }

    compute
  end

  def default_store
    stops.clear
    stops.build(destination:planning.customer.store, active:true, index:0)
    stops.build(destination:planning.customer.store, active:true, index:1)
  end

  def compute
    self.out_of_date = false
    self.distance = 0
    self.emission = 0
    self.start = self.end = nil
    if vehicle
      self.end = self.start = vehicle.open
      last = stops[0]
      last.time = self.end
      quantity = 0
      stops_sort = stops.sort_by(&:index)[1..-1]
      router_url = stops_sort[0].destination.customer && stops_sort[0].destination.customer.router.url
      stops_sort.each{ |stop|
        destination = stop.destination
        if stop.active && destination.lat && destination.lng
          stop.distance, time, stop.trace = if router_url
            Trace.compute(router_url, last.destination.lat, last.destination.lng, destination.lat, destination.lng)
          else
            [0, 0, nil]
          end
          stop.time = self.end + time
          if destination.open && stop.time < destination.open
            stop.time = destination.open
          end
          stop.out_of_window = (destination.open && stop.time < destination.open) || (destination.close && stop.time > destination.close)

          self.distance += stop.distance
          take_over = destination.take_over ? destination.take_over : destination.customer && destination.customer.take_over
          take_over = take_over ? take_over.seconds_since_midnight : 0
          self.end = stop.time + take_over

          quantity += (destination.quantity or 1)
          stop.out_of_capacity = destination.customer && vehicle.capacity && quantity > vehicle.capacity

          stop.out_of_drive_time = destination.customer && stop.time > vehicle.close

          last = stop
        else
          stop.active = stop.out_of_capacity = stop.out_of_drive_time = false
          stop.distance = stop.trace = stop.time = nil
        end
        self.emission = self.distance / 1000 * vehicle.emission * vehicle.consumption / 100
      }
    end
  end

  def set_destinations(dests)
    Stop.transaction do
      stops.clear
      add_destinations(dests)
    end
  end

  def add_destinations(dests)
    Stop.transaction do
      dests.select!{ |d| d[0] != planning.customer.store }
      if vehicle
        dests = [[planning.customer.store, true]] + dests + [[planning.customer.store, true]]
      end
      i = 0
      dests.each{ |stop|
        destination, active = stop
        s = stops.build(destination:destination, active:active, index:i+=1)
        destination.stops << s
      }
      compute
    end
  end

  def add(destination, index = nil, active = false)
    if index
      stops.partition{ |stop|
        stop.index < index
      }[1].each{ |stop|
        stop.index += 1
      }
    elsif vehicle
      raise
    end
    s = stops.build(destination: destination, index: index, active: active)
    destination.stops << s # FIXME workaround, this line is not needed

    if self.vehicle
      self.out_of_date = true
    end
  end

  def remove(destination)
    stops.each{ |stop|
      if(stop.destination ==  destination)
        stop.destroy
        if self.vehicle
          self.out_of_date = true
        end
      end
    }
  end

  def sum_out_of_window
    stops.to_a.sum{ |stop|
      (stop.time && stop.destination.open && stop.time < stop.destination.open ? stop.destination.open - stop.time : 0) +
      (stop.time && stop.destination.close && stop.time > stop.destination.close ? stop.time - stop.destination.close : 0)
    }
  end

  def matrix_size
    stops_segregate[true].size
  end

  def matrix
    stops_on = stops_segregate[true]
    router_url = stops_on[1].destination.customer.router.url
    stops_on.collect{ |stop1|
      stops_on.collect{ |stop2|
        distance, time, trace = Trace.compute(router_url, stop1.destination.lat, stop1.destination.lng, stop2.destination.lat, stop2.destination.lng)
        yield if block_given?
        [distance, time]
      }
    }
  end

  def order(o)
    stops_ = stops_segregate
    a = o[0..-2].collect{ |i|
      stops_[true][i].out_of_window = false
      stops_[true][i]
    }
    a = a + ((1..stops_[true].size-1).to_a - o[1..-2]).collect{ |i|
      stops_[true][i].active = false
      stops_[true][i].out_of_window = true
      stops_[true][i]
    }
    a = a + (stops_[false] || []) + stops[-1..-1]
    i = 0
    a.each{ |stop|
      stop.index = i
      i += 1
    }
  end

  def size
    stops.to_a.sum(0) { |stop|
      stop.destination.customer && (stop.active || ! vehicle) ? 1 : 0
    }
  end

  def quantity
    stops.to_a.sum(0) { |stop|
      stop.destination.customer && (stop.active || ! vehicle) ? (stop.destination.quantity or 1) : 0
    }
  end

  def active_all
    stops.each { |stop|
      if stop.destination.lat && stop.destination.lng
        stop.active = true
      end
    }
    compute
  end

  def out_of_date
    self.vehicle && self[:out_of_date]
  end

  private
    def assign_defaults
      self.hidden = false
      self.locked = false
    end

    def stops_segregate
      stops[0..-2].group_by{ |stop| !!(stop.active && stop.destination.lat && stop.destination.lng) }
    end
end
