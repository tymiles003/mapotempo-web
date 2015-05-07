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
  has_many :stops, -> { order(:index) }, inverse_of: :route, autosave: true, dependent: :delete_all

  nilify_blanks
  auto_strip_attributes :ref
  validates :planning, presence: true
#  validates :vehicle, presence: true # nil on unplanned route
  validate :stop_index_validation

  after_initialize :assign_defaults, if: 'new_record?'

  amoeba do
    enable

    customize(lambda { |original, copy|
      copy.planning = original.planning
      copy.stops.each{ |stop|
        stop.route = copy
      }
    })
  end

  def init_stops
    stops.clear
    if vehicle && vehicle.rest_duration
      stops.build(type: StopRest.name, active: true, index: 1)
    end

    compute
  end

  def default_stops
    i = stops.size
    planning.destinations_compatibles.each { |c|
      stops.build(type: StopDestination.name, destination: c, active: true, index: i += 1)
    }
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
      speed_multiplicator = (planning.customer.speed_multiplicator || 1) * (vehicle.speed_multiplicator || 1)
      last_lat, last_lng = vehicle.store_start.lat, vehicle.store_start.lng
      quantity = 0
      router = vehicle.router || planning.customer.router
      stops_time = {}
      stops_sort = stops.sort_by(&:index)
      stops_sort.each{ |stop|
        if stop.active && (stop.position? || stop.is_a?(StopRest))
          if stop.position?
            stop.distance, time, stop.trace = router.trace(speed_multiplicator, last_lat, last_lng, stop.lat, stop.lng)
          else
            stop.distance, time, stop.trace = 0, 0, nil
          end
          stops_time[stop] = time
          stop.time = self.end + time
          if stop.open && stop.time < stop.open
            stop.wait_time = stop.open - stop.time
            stop.time = stop.open
          else
            stop.wait_time = nil
          end
          stop.out_of_window = (stop.open && stop.time < stop.open) || (stop.close && stop.time > stop.close)

          self.distance += stop.distance
          self.end = stop.time + stop.duration

          if stop.is_a?(StopDestination)
            quantity += (stop.destination.quantity || 1)
            stop.out_of_capacity = vehicle.capacity && quantity > vehicle.capacity
          end

          stop.out_of_drive_time = stop.time > vehicle.close

          if stop.position?
            last_lat, last_lng = stop.lat, stop.lng
          end
        else
          stop.active = stop.out_of_capacity = stop.out_of_drive_time = false
          stop.distance = stop.trace = stop.time = stop.wait_time = nil
        end
      }

      distance, time, trace = router.trace(speed_multiplicator, last_lat, last_lng, vehicle.store_stop.lat, vehicle.store_stop.lng)
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
        if stop.active && stop.position?
          if stop.out_of_window
            time = stop.time
          else
            # Latest departure time
            time = stop.close ? [time, stop.close].min : time

            # New arrival stop time
            time -= stop.duration
          end

          # Previous departure time
          time -= stops_time[stop]
        end
      }

      if time > start
        # We can sleep a bit more on morning, shift departure
        plan(time)
      end
    end

    true
  end

  def set_destinations(dests, recompute = true)
    Stop.transaction do
      stops.select{ |stop| stop.is_a?(StopDestination) }.each{ |stop|
        remove_stop(stop)
      }
      add_destinations(dests, recompute)
    end
  end

  def add_destinations(dests, recompute = true)
    Stop.transaction do
      i = 0
      dests.each{ |stop|
        destination, active = stop
        stops.build(type: StopDestination.name, destination: destination, active: active, index: i += 1)
      }
      compute if recompute
    end
  end

  def add(destination, index = nil, active = false)
    index = stops.size + 1 if index && index < 0
    if index
      shift_index(index)
    elsif vehicle
      raise
    end
    stops.build(type: StopDestination.name, destination: destination, index: index, active: active)

    if vehicle
      self.out_of_date = true
    end
  end

  def remove_destination(destination)
    stops.each{ |stop|
      if(stop.is_a?(StopDestination) && stop.destination == destination)
        remove_stop(stop)
      end
    }
  end

  def remove_stop(stop)
    if vehicle
      shift_index(stop.index + 1, -1)
      self.out_of_date = true
    end
    stops.destroy(stop)
  end

  def move_destination(destination, index)
    stop = nil
    planning.routes.find{ |route|
      (route != self ? route : self).stops.find{ |s|
        if s.is_a?(StopDestination) && s.destination == destination
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
      if stop.is_a?(StopDestination)
        destination, active = stop.destination, stop.active
        stop.route.move_stop_out(stop)
        add(destination, index, active || stop.route.vehicle.nil?)
      end
    else
      index = stops.size if index < 0
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
    if stop.is_a?(StopDestination)
      if vehicle
        shift_index(stop.index + 1, -1)
      end
      stop.active = false
      compute
      stop.route.stops.destroy(stop)
    end
  end

  def sum_out_of_window
    stops.to_a.sum{ |stop|
      (stop.time && stop.open && stop.time < stop.open ? stop.open - stop.time : 0) +
      (stop.time && stop.close && stop.time > stop.close ? stop.time - stop.close : 0)
    }
  end

  def optimize(matrix_progress, &optimizer)
    stops_on = stops_segregate[true]
    router = vehicle.router || planning.customer.router
    amalgamate_stops_same_position(stops_on) { |positions|
      tws = [[nil, nil, 0]] + positions.collect{ |position|
        open, close, duration = position[2..4]
        open = open ? Integer(open - vehicle.open) : nil
        close = close ? Integer(close - vehicle.open) : nil
        if open && close && open > close
          close = open
        end
        [open, close, duration]
      }

      positions = [[vehicle.store_start.lat, vehicle.store_start.lng]] + positions + [[vehicle.store_stop.lat, vehicle.store_stop.lng]]
      speed_multiplicator = (planning.customer.speed_multiplicator || 1) * (vehicle.speed_multiplicator || 1)
      matrix = router.matrix(positions, speed_multiplicator, &matrix_progress)

      optimizer.call(matrix, tws)[1..-2].collect{ |i| i - 1 }
    }
  end

  def order(o)
    stops_ = stops_segregate
    a = o.collect{ |i|
      stops_[true][i].out_of_window = false
      stops_[true][i]
    }
    a += ((0..stops_[true].size - 1).to_a - o).collect{ |i|
      stops_[true][i].active = false
      stops_[true][i].out_of_window = true
      stops_[true][i]
    }
    a += (stops_[false] || [])
    i = 0
    a.each{ |stop|
      stop.index = i += 1
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
      (stop.active || !vehicle) ? 1 : 0
    }
  end

  def quantity
    stops.to_a.sum(0) { |stop|
      stop.is_a?(StopDestination) && (stop.active || !vehicle) ? (stop.destination.quantity || 1) : 0
    }
  end

  def active_all
    stops.each { |stop|
      if stop.position?
        stop.active = true
      end
    }
    compute
  end

  def out_of_date
    vehicle && self[:out_of_date]
  end

  def to_s
    "#{ref}:#{vehicle && vehicle.name}=>[" + stops.collect(&:to_s).join(', ') + ']'
  end

  private

  def assign_defaults
    self.hidden = false
    self.locked = false
  end

  def stops_segregate
    stops.group_by{ |stop| !!(stop.active && stop.position?) }
  end

  def shift_index(from, by = 1, to = nil)
    stops.partition{ |stop|
      stop.index.nil? || stop.index < from || (to && stop.index > to)
    }[1].each{ |stop|
      stop.index += by
    }
  end

  def stop_index_validation
    if vehicle_id && stops.length > 0 && stops.collect(&:index).sum != (stops.length * (stops.length + 1)) / 2
      errors.add(:stops, :bad_index)
    end
  end

  def amalgamate_stops_same_position(stops)
    tws = stops.find{ |stop|
      stop.is_a?(StopRest) || stop.open || stop.close
    }

    if tws
      # Can't reduce cause of time windows
      positions_uniq = stops.collect{ |stop|
        [stop.lat, stop.lng, stop.open, stop.close, stop.duration]
      }

      yield(positions_uniq)
    else
      # Reduce positions vector size by amalgamate points in same position
      stock = Hash.new { Array.new }
      i = -1
      stops.each{ |stop|
        stock[[stop.lat, stop.lng]] += [[stop, i += 1]]
      }

      positions_uniq = stock.collect{ |k, v|
        k + [nil, nil, v.sum{ |vs| vs[0].duration }]
      }

      optim_uniq = yield(positions_uniq)

      optim_uniq.collect{ |ou|
        stock[positions_uniq[ou][0..1]]
      }.flatten(1).collect{ |pa|
        pa[1]
      }
    end
  end
end
