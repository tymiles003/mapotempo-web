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
class Route < ActiveRecord::Base
  belongs_to :planning
  belongs_to :vehicle
  has_many :stops, -> { order(:index) }, inverse_of: :route, :autosave => true, :dependent => :delete_all

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
    planning.destinations_compatibles.each { |c|
      stops.build(destination:c, active:true, index:i+=1)
    }

    compute
  end

  def plan(departure = nil)
    self.out_of_date = false
    self.distance = 0
    self.stop_distance = 0
    self.stop_trace = nil
    self.stop_out_of_drive_time = nil
    self.emission = 0
    self.start = self.end = nil
    if vehicle && stops.size > 0
      self.end = self.start = departure || vehicle.open
      last = vehicle.store_start
      quantity = 0
      router = vehicle.router || stops[0].destination.customer.router
      stops_time = {}
      stops_sort = stops.sort_by(&:index)
      stops_sort.each{ |stop|
        destination = stop.destination
        if stop.active && destination.lat != nil && destination.lng != nil
          stop.distance, time, stop.trace = router.trace(last.lat, last.lng, destination.lat, destination.lng)
          stops_time[stop] = time
          stop.time = self.end + time
          if destination.open && stop.time < destination.open
            stop.wait_time = destination.open - stop.time
            stop.time = destination.open
          else
            stop.wait_time = nil
          end
          stop.out_of_window = (destination.open && stop.time < destination.open) || (destination.close && stop.time > destination.close)

          self.distance += stop.distance
          take_over = destination.take_over ? destination.take_over : destination.customer.take_over
          take_over = take_over ? take_over.seconds_since_midnight : 0
          self.end = stop.time + take_over

          quantity += (destination.quantity or 1)
          stop.out_of_capacity = vehicle.capacity && quantity > vehicle.capacity

          stop.out_of_drive_time = stop.time > vehicle.close

          last = stop.destination
        else
          stop.active = stop.out_of_capacity = stop.out_of_drive_time = false
          stop.distance = stop.trace = stop.time = stop.wait_time = nil
        end
      }

      distance, time, trace = router.trace(last.lat, last.lng, vehicle.store_stop.lat, vehicle.store_stop.lng)
      self.distance += distance
      stops_time[:stop] = time
      self.end += time
      self.stop_distance = distance
      self.stop_trace = trace
      self.stop_out_of_drive_time = self.end > vehicle.close

      self.emission = self.distance / 1000 * vehicle.emission * vehicle.consumption / 100

      [stops_sort, stops_time]
    end
  end

  def compute
    stops_sort, stops_time = plan

    if stops_sort
      # Try to minimize waiting time by a later begin
      time = self.end - stops_time[:stop]
      stops_sort.reverse_each{ |stop|
        destination = stop.destination
        if stop.active && destination.lat != nil && destination.lng != nil
          if stop.out_of_window
            time = stop.time
          else
            # Latest departure time
            time = destination.close ? [time, destination.close].min : time

            take_over = destination.take_over ? destination.take_over : destination.customer.take_over
            take_over = take_over ? take_over.seconds_since_midnight : 0

            # New arrival stop time
            time -= take_over
          end

          # Previous departure time
          time -= stops_time[stop]
        end
      }

      if time > self.start
        # We can sleep a bit more on morning, shift departure
        plan(time)
      end
    end

    true
  end


  def set_destinations(dests, recompute = true)
    Stop.transaction do
      stops.clear
      add_destinations(dests, recompute)
    end
  end

  def add_destinations(dests, recompute = true)
    Stop.transaction do
      i = 0
      dests.each{ |stop|
        destination, active = stop
        stops.build(destination:destination, active:active, index:i+=1)
      }
      compute if recompute
    end
  end

  def add(destination, index = nil, active = false)
    if index
      shift_index(index)
    elsif vehicle
      raise
    end
    stops.build(destination: destination, index: index, active: active)

    if self.vehicle
      self.out_of_date = true
    end
  end

  def remove_destination(destination)
    stops.each{ |stop|
      if(stop.destination == destination)
        remove_stop(stop)
      end
    }
  end

  def remove_stop(stop)
    shift_index(stop.index + 1, -1)
    stop.destroy
    if self.vehicle
      self.out_of_date = true
    end
  end

  def move_destination(destination, index)
    stop = nil
    planning.routes.find{ |route|
      route.stops.find{ |s|
        if s.destination == destination
          stop = s
        end
      }
    }
    if stop
      move_stop(stop, index)
    end
  end

  def move_stop(stop, index)
    if stop.route != self
      destination, active = stop.destination, stop.active
      stop.route.move_stop_out(stop)
      add(destination, index, active || stop.route.vehicle == nil)
    else
      if stop.index
        if index < stop.index
          shift_index(index, 1, stop.index - 1)
        else
          shift_index(stop.index + 1, -1, index)
        end
        stop.index = index
      end
    end
    compute
  end

  def move_stop_out(stop)
    if vehicle
      shift_index(stop.index + 1, -1)
    end
    stop.active = false
    compute
    stop.destroy
  end

  def sum_out_of_window
    stops.to_a.sum{ |stop|
      (stop.time && stop.destination.open && stop.time < stop.destination.open ? stop.destination.open - stop.time : 0) +
      (stop.time && stop.destination.close && stop.time > stop.destination.close ? stop.time - stop.destination.close : 0)
    }
  end

  def matrix_size
    stops_segregate[true] ? stops_segregate[true].size + 2 : 0
  end

  def matrix(&block)
    stops_on = stops_segregate[true]
    positions = [vehicle.store_start] + stops_on.collect(&:destination) + [vehicle.store_stop]
    router = vehicle.router || stops_on[0].destination.customer.router
    router.matrix(positions, &block)
  end

  def order(o)
    stops_ = stops_segregate
    a = o.collect{ |i|
      stops_[true][i].out_of_window = false
      stops_[true][i]
    }
    a += ((0..stops_[true].size-1).to_a - o).collect{ |i|
      stops_[true][i].active = false
      stops_[true][i].out_of_window = true
      stops_[true][i]
    }
    a += (stops_[false] || [])
    i = 0
    a.each{ |stop|
      stop.index = i+=1
    }
  end

  def active(action)
    if action == :reverse
      stops.each{ |stop|
        stop.active = !stop.active
      }
      true
    elsif action == :all || action == :none
      stops.each{ |stop|
        stop.active = action == :all
      }
      true
    else
      false
    end
  end

  def size_active
    stops.to_a.sum(0) { |stop|
      (stop.active || ! vehicle) ? 1 : 0
    }
  end

  def quantity
    stops.to_a.sum(0) { |stop|
      (stop.active || ! vehicle) ? (stop.destination.quantity or 1) : 0
    }
  end

  def active_all
    stops.each { |stop|
      if stop.destination.lat != nil && stop.destination.lng != nil
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
      stops.group_by{ |stop| !!(stop.active && stop.destination.lat != nil && stop.destination.lng != nil) }
    end

    def shift_index(from, by = 1, to = nil)
      stops.partition{ |stop|
        stop.index == nil || stop.index < from || (to && stop.index > to)
      }[1].each{ |stop|
        stop.index += by
      }
    end
end
