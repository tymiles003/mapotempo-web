# Copyright © Mapotempo, 2013-2016
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
  belongs_to :vehicle_usage
  has_many :stops, -> { order(:index) }, inverse_of: :route, autosave: true, dependent: :delete_all, after_add: :update_stops_track, after_remove: :update_stops_track

  nilify_blanks
  validates :planning, presence: true
#  validates :vehicle_usage, presence: true # nil on unplanned route
  validate :stop_index_validation

  before_save :update_vehicle_usage

  after_initialize :assign_defaults, if: 'new_record?'

  scope :for_customer, lambda{ |customer| where(planning_id: customer.planning_ids) }

  include RefSanitizer

  amoeba do
    enable

    customize(lambda { |original, copy|
      def copy.update_vehicle_usage; end
      def copy.assign_defaults; end
      copy.planning = original.planning
      copy.stops.each{ |stop|
        stop.route = copy
      }
    })
  end

  def init_stops(ignore_errors = false)
    stops.clear
    if vehicle_usage && vehicle_usage.default_rest_duration
      stops.build(type: StopRest.name, active: true, index: 1)
    end

    compute(ignore_errors: ignore_errors)
  end

  def default_stops
    i = stops.size
    planning.visits_compatibles.each { |visit|
      stops.build(type: StopVisit.name, visit: visit, active: true, index: i += 1)
    }
  end

  def service_time_start_value
    vehicle_usage.default_service_time_start - Time.utc(2000, 1, 1, 0, 0) if vehicle_usage && vehicle_usage.default_service_time_start
  end

  def service_time_end_value
    vehicle_usage.default_service_time_end - Time.utc(2000, 1, 1, 0, 0) if vehicle_usage && vehicle_usage.default_service_time_end
  end

  def plan(departure = nil, ignore_errors = false)
    self.touch if self.id # To force route save in case none attribute has changed below
    self.out_of_date = false
    self.distance = 0
    self.stop_distance = 0
    self.stop_trace = nil
    self.stop_out_of_drive_time = nil
    self.emission = 0
    self.start = self.end = nil
    last_lat, last_lng = nil, nil
    if vehicle_usage && !stops.empty?
      service_time_start = service_time_start_value
      service_time_end = service_time_end_value
      self.end = self.start = departure || vehicle_usage.default_open
      speed_multiplicator = vehicle_usage.vehicle.default_speed_multiplicator
      if vehicle_usage.default_store_start && vehicle_usage.default_store_start.position?
        last_lat, last_lng = vehicle_usage.default_store_start.lat, vehicle_usage.default_store_start.lng
      end
      quantity1_1 = quantity1_2 = 0
      router = vehicle_usage.vehicle.default_router
      router_dimension = vehicle_usage.vehicle.default_router_dimension
      stops_drive_time = {}

      # Add service time
      if !service_time_start.nil?
        self.end += service_time_start
      end

      speed_multiplicator_areas = planning.zonings.collect(&:zones).flatten.select{ |z| z.speed_multiplicator != 1 }.collect{ |z|
        feat = RGeo::GeoJSON.decode(z.polygon, json_parser: :json)
        coordinates = feat.geometry.coordinates[0] if feat && feat.geometry.geometry_type == RGeo::Feature::Polygon
        coordinates = feat.geometry.coordinates[0][0] if feat && feat.geometry.geometry_type == RGeo::Feature::MultiPolygon
        {
          area: coordinates.collect(&:reverse),
          speed_multiplicator_area: z.speed_multiplicator
        }
      }

      stops_sort = stops.sort_by(&:index)

      # Collect route legs
      segments = stops_sort.select{ |stop|
        stop.active && (stop.position? || (stop.is_a?(StopRest) && ((stop.open1 && stop.close1) || (stop.open2 && stop.close2)) && stop.duration))
      }.collect{ |stop|
        if stop.position? && !last_lat.nil? && !last_lng.nil?
          ret = [last_lat, last_lng, stop.lat, stop.lng]
        end
        if stop.position?
          last_lat, last_lng = stop.lat, stop.lng
        end
        ret
      }

      if !last_lat.nil? && !last_lng.nil? && vehicle_usage.default_store_stop && vehicle_usage.default_store_stop.position?
        segments << [last_lat, last_lng, vehicle_usage.default_store_stop.lat, vehicle_usage.default_store_stop.lng]
      else
        segments << nil
      end

      # Compute legs traces
      traces = [nil, nil, nil] * segments.size
      begin
        ts = router.trace_batch(speed_multiplicator, segments.select{ |segment| !segment.nil? }, router_dimension, speed_multiplicator_areas: speed_multiplicator_areas)
        traces = segments.collect{ |segment|
          if segment.nil?
            [nil, nil, nil]
          else
            (ts && !ts.empty? && ts.shift) || [nil, nil, nil]
          end
        }
      rescue RouterError
        if !ignore_errors
          raise
        end
      end
      traces[0] = [0, 0, nil] if !vehicle_usage.default_store_start || !vehicle_usage.default_store_start.position?

      # Recompute Stops
      stops_time_windows = {}
      stops_sort.each{ |stop|
        if stop.active && (stop.position? || (stop.is_a?(StopRest) && ((stop.open1 && stop.close1) || (stop.open2 && stop.close2)) && stop.duration))
          stop.distance, stop.drive_time, stop.trace = traces.shift
          if stop.drive_time
            stops_drive_time[stop] = stop.drive_time
            stop.time = self.end + stop.drive_time
          elsif stop.is_a?(StopRest)
            stop.time = self.end
          else
            stop.time = nil
          end

          if stop.time
            open, close, late_wait = stop.best_open_close(stop.time)
            stops_time_windows[stop] = [open, close]
            if open && stop.time < open
              stop.wait_time = open - stop.time
              stop.time = open
            else
              stop.wait_time = nil
            end
            stop.out_of_window = late_wait && late_wait > 0

            if stop.distance
              self.distance += stop.distance
            end
            self.end = stop.time + stop.duration

            if stop.is_a?(StopVisit)
              quantity1_1 += (stop.visit.quantity1_1 || 1)
              quantity1_2 += (stop.visit.quantity1_2 || 1)
              stop.out_of_capacity = (vehicle_usage.vehicle.capacity1_1 && quantity1_1 > vehicle_usage.vehicle.capacity1_1) || (vehicle_usage.vehicle.capacity1_2 && quantity1_2 > vehicle_usage.vehicle.capacity1_2)
            end

            stop.out_of_drive_time = stop.time > vehicle_usage.default_close
          end
        else
          stop.active = stop.out_of_capacity = stop.out_of_drive_time = stop.out_of_window = false
          stop.distance = stop.trace = stop.time = stop.wait_time = nil
        end
      }

      # Last stop to store
      distance, drive_time, trace = traces.shift
      if drive_time
        self.distance += distance
        stops_drive_time[:stop] = drive_time
        self.end += drive_time
        self.stop_distance, self.stop_drive_time = distance, drive_time
      end

      # Add service time to end point
      if !service_time_end.nil?
        self.end += service_time_end
      end

      self.stop_trace = trace
      self.stop_out_of_drive_time = self.end > vehicle_usage.default_close

      self.emission = vehicle_usage.vehicle.emission.nil? || vehicle_usage.vehicle.consumption.nil? ? nil : self.distance / 1000 * vehicle_usage.vehicle.emission * vehicle_usage.vehicle.consumption / 100

      [stops_sort, stops_drive_time, stops_time_windows]
    end
  end

  def compute(options = {})
    stops_sort, stops_drive_time, stops_time_windows = plan(nil, options[:ignore_errors])

    if stops_sort
      # Try to minimize waiting time by a later begin
      time = self.end
      time -= stops_drive_time[:stop] if stops_drive_time[:stop]
      (time -= vehicle_usage.default_service_time_end - Time.utc(2000, 1, 1, 0, 0)) if vehicle_usage.default_service_time_end
      stops_sort.reverse_each{ |stop|
        if stop.active && (stop.position? || stop.is_a?(StopRest))
          open, close = stops_time_windows[stop]
          if stop.time && (stop.out_of_window || (close && time > close))
            time = [stop.time, close ? close - stop.duration : 0].max
          else
            # Latest departure time
            time = [time, close].min if close

            # New arrival stop time
            time -= stop.duration
          end

          # Previous departure time
          time -= stops_drive_time[stop] if stops_drive_time[stop]
        end
      }

      (time -= vehicle_usage.default_service_time_start - Time.utc(2000, 1, 1, 0, 0)) if vehicle_usage.default_service_time_start
      if time > start
        # We can sleep a bit more on morning, shift departure
        plan(time, options[:ignore_errors])
      end
    end

    true
  end

  def set_visits(visits, recompute = true, ignore_errors = false)
    Stop.transaction do
      stops.select{ |stop| stop.is_a?(StopVisit) }.each{ |stop|
        remove_stop(stop)
      }
      add_visits(visits, recompute, ignore_errors)
    end
  end

  def add_visits(visits, recompute = true, ignore_errors = false)
    Stop.transaction do
      i = stops.size
      visits.each{ |stop|
        visit, active = stop
        stops.build(type: StopVisit.name, visit: visit, active: active, index: i += 1)
      }
      if vehicle_usage
        self.out_of_date = true
        self.optimized_at = nil
      end
      compute(ignore_errors: ignore_errors) if recompute
    end
  end

  def add(visit, index = nil, active = false, stop_id = nil)
    index = stops.size + 1 if index && index < 0
    if index
      shift_index(index)
    elsif vehicle_usage
      raise
    end
    stops.build(type: StopVisit.name, visit: visit, index: index, active: active, id: stop_id)

    if vehicle_usage
      self.out_of_date = true
      self.optimized_at = nil
    end
  end

  def add_rest(active = true, stop_id = nil)
    index = stops.size + 1
    stops.build(type: StopRest.name, index: index, active: active, id: stop_id)
    self.out_of_date = true
    self.optimized_at = nil if vehicle_usage
  end

  def add_or_update_rest(active = true, stop_id = nil)
    if !stops.find{ |stop| stop.is_a?(StopRest) }
      add_rest(active, stop_id)
    end
    self.out_of_date = true
    self.optimized_at = nil if vehicle_usage
  end

  def remove_visit(visit)
    stops.each{ |stop|
      if stop.is_a?(StopVisit) && stop.visit == visit
        remove_stop(stop)
      end
    }
  end

  def remove_stop(stop)
    if vehicle_usage
      shift_index(stop.index + 1, -1)
      self.out_of_date = true
      self.optimized_at = nil
    end
    stops.destroy(stop)
  end

  def move_stop(stop, index)
    index = stops.size if index < 0
    if stop.index
      if index < stop.index
        shift_index(index, 1, stop.index - 1)
      else
        shift_index(stop.index + 1, -1, index)
      end
      stop.index = index
    end
    self.optimized_at = nil if vehicle_usage
    compute
  end

  def move_stop_out(stop, force = false)
    if force || stop.is_a?(StopVisit)
      if vehicle_usage
        shift_index(stop.index + 1, -1)
        self.optimized_at = nil
      end
      stop.active = false
      compute
      stop.route.stops.destroy(stop)
    end
  end

  def force_reindex
    # Force reindex after customers.destination.destroy_all
    stops.each_with_index{ |stop, index|
      stop.index = index + 1
    }
  end

  def sum_out_of_window
    stops.to_a.sum{ |stop|
      if stop.time
        open, close = stop.best_open_close(stop.time)
        (open && stop.time < open ? open - stop.time : 0) + (close && stop.time > close ? stop.time - close : 0)
      else
        0
      end
    }
  end

  def optimize(matrix_progress, &optimizer)
    router = vehicle_usage.vehicle.default_router
    router_dimension = vehicle_usage.vehicle.default_router_dimension
    speed_multiplicator_areas = planning.zonings.collect(&:zones).flatten.select{ |z| z.speed_multiplicator != 1 }.collect{ |z|
      feat = RGeo::GeoJSON.decode(z.polygon, json_parser: :json)
      coordinates = feat.geometry.coordinates[0] if feat && feat.geometry.geometry_type == RGeo::Feature::Polygon
      coordinates = feat.geometry.coordinates[0][0] if feat && feat.geometry.geometry_type == RGeo::Feature::MultiPolygon
      {
        area: coordinates.collect(&:reverse),
        speed_multiplicator_area: z.speed_multiplicator
      }
    }

    stops_on = stops_segregate[true]
    o = amalgamate_stops_same_position(stops_on) { |positions|

      services_and_rests = positions.collect{ |position|
        open1, close1, open2, close2, duration = position[2..6]
        vehicle_open = vehicle_usage.default_open
        vehicle_open += vehicle_usage.default_service_time_start - Time.utc(2000, 1, 1, 0, 0) if vehicle_usage.default_service_time_start

        open1 = open1 ? Integer(open1 - vehicle_open) : nil
        close1 = close1 ? Integer(close1 - vehicle_open) : nil
        if open1 && close1 && open1 > close1
          close1 = open1
        end
        open2 = open2 ? Integer(open2 - vehicle_open) : nil
        close2 = close2 ? Integer(close2 - vehicle_open) : nil
        if open2 && close2 && open2 > close2
          close2 = open2
        end

        {start1: open1, end1: close1, start2: open2, end2: close2, duration: duration}
      }

      unnil_positions(positions, services_and_rests){ |positions, services, rests|
        position_start = (vehicle_usage.default_store_start && !vehicle_usage.default_store_start.lat.nil? && !vehicle_usage.default_store_start.lng.nil?) ? [vehicle_usage.default_store_start.lat, vehicle_usage.default_store_start.lng] : nil
        position_stop = (vehicle_usage.default_store_stop && !vehicle_usage.default_store_stop.lat.nil? && !vehicle_usage.default_store_stop.lng.nil?) ? [vehicle_usage.default_store_stop.lat, vehicle_usage.default_store_stop.lng] : nil
        positions = ([position_start] + positions + [position_stop]).compact.collect{ |position| position[0..1] }
        matrix = router.matrix(positions, positions, vehicle_usage.vehicle.default_speed_multiplicator, router_dimension, speed_multiplicator_areas: speed_multiplicator_areas, &matrix_progress)
        order = optimizer.call(matrix, services, [position_start && :start, position_stop && :stop].compact, rests, router_dimension)
        if position_stop
          order = order[0..-2].collect{ |i| i > order.size - 2 ? i - 1 : i }
        end
        if position_start
          order = order[1..-1].collect{ |i| i - 1 }
        end
        order
      }
    }
    self.optimized_at = Time.now.utc
    o
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
    return false if ![:reverse, :all, :none].include?(action)
    stops.each{ |stop|
      stop.active = action == :reverse ? !stop.active : action == :all
    }
    self.optimized_at = nil
    true
  end

  def size_active
    stops.to_a.sum(0) { |stop|
      (stop.active || !vehicle_usage) ? 1 : 0
    }
  end

  include LocalizedAttr

  attr_localized :quantity1_1, :quantity1_2

  def quantity1_1
    stops.to_a.sum(0) { |stop|
      stop.is_a?(StopVisit) && (stop.active || !vehicle_usage) ? (stop.visit.quantity1_1 || 1) : 0
    }
  end

  def quantity1_2
    stops.to_a.sum(0) { |stop|
      stop.is_a?(StopVisit) && (stop.active || !vehicle_usage) ? (stop.visit.quantity1_2 || 0) : 0
    }
  end

  def quantity?
    quantity1_1 > 0 || quantity1_2 > 0
  end

  def active_all
    stops.each { |stop|
      if stop.position?
        stop.active = true
      end
    }
    self.optimized_at = nil
    compute
  end

  def reverse_order
    self.optimized_at = nil
    stops.sort_by{ |stop| -stop.index }.each_with_index{ |stop, index|
      stop.index = index + 1
    }
  end

  def out_of_date
    vehicle_usage && self[:out_of_date]
  end

  def changed?
    @stops_updated || super || stops.any?(&:changed?)
  end

  def to_s
    "#{ref}:#{vehicle_usage && vehicle_usage.vehicle.name}=>[" + stops.collect(&:to_s).join(', ') + ']'
  end

  private

  def assign_defaults
    self.hidden = false
    self.locked = false
  end

  def stops_segregate
    stops.group_by{ |stop| !!(stop.active && (stop.position? || stop.is_a?(StopRest))) }
  end

  def shift_index(from, by = 1, to = nil)
    stops.partition{ |stop|
      stop.index.nil? || stop.index < from || (to && stop.index > to)
    }[1].each{ |stop|
      stop.index += by
    }
  end

  def stop_index_validation
    if vehicle_usage_id && !stops.empty? && stops.collect(&:index).sum != (stops.length * (stops.length + 1)) / 2
      errors.add(:stops, :bad_index)
    end
  end

  def amalgamate_stops_same_position(stops)
    tws = stops.find{ |stop|
      stop.is_a?(StopRest) || stop.open1 || stop.close1 || stop.open2 || stop.close2
    }

    if tws
      # Can't reduce cause of time windows
      positions_uniq = stops.collect{ |stop|
        [stop.lat, stop.lng, stop.open1, stop.close1, stop.open2, stop.close2, stop.duration]
      }

      yield(positions_uniq)
    else
      # Reduce positions vector size by amalgamate points in same position
      stock = Hash.new { [] }
      i = -1
      stops.each{ |stop|
        stock[[stop.lat, stop.lng]] += [[stop, i += 1]]
      }

      positions_uniq = stock.collect{ |k, v|
        k + [nil, nil, nil, nil, v.sum{ |vs| vs[0].duration }]
      }

      optim_uniq = yield(positions_uniq)

      optim_uniq.flat_map{ |ou|
        stock[positions_uniq[ou][0..1]]
      }.collect{ |pa|
        pa[1]
      }
    end
  end

  def unnil_positions(positions, tws)
    not_nil_position_index = positions.each_with_index.group_by{ |position, _index| !position[0].nil? && !position[1].nil? }

    if not_nil_position_index.key?(true)
      not_nil_position, not_nil_tws, not_nil_index = not_nil_position_index[true].collect{ |position, index| [position, tws[index], index] }.transpose
    else
      not_nil_position = not_nil_tws = not_nil_index = []
    end
    if not_nil_position_index.key?(false)
      nil_tws, nil_index = not_nil_position_index[false].collect{ |_position, index| [tws[index], index] }.transpose
    else
      nil_tws = nil_index = []
    end

    order = yield(not_nil_position, not_nil_tws, nil_tws)

    all_index = not_nil_index + nil_index
    order.collect{ |o| all_index[o] }
  end

  def update_stops_track(_stop)
    @stops_updated = true
  end

  def update_vehicle_usage
    if vehicle_usage_id_changed?
      if vehicle_usage.default_rest_duration.nil?
        stops.select{ |stop| stop.is_a?(StopRest) }.each{ |stop|
          remove_stop(stop)
        }
      elsif !stops.any?{ |stop| stop.is_a?(StopRest) }
        add_rest
      end
      self.out_of_date = true if id || out_of_date.nil?
      self.optimized_at = nil
    end
  end
end
