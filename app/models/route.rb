require 'trace'

class Route < ActiveRecord::Base
  belongs_to :planning, touch: true
  belongs_to :vehicle
  has_many :stops, :autosave => true, :dependent => :destroy, :order=>"\"index\" ASC", :include=>:destination

#  validates :planning, presence: true
#  validates :vehicle, presence: true
  validate :validate_stops_length

  after_initialize :assign_defaults, if: 'new_record?'

  def default_stops
    i = 0
    stops.clear
    planning.customer.destinations.select{ |c|
      c != planning.customer.store
    }.select{ |c|
      planning.tags & c.tags == planning.tags
    }.each { |c|
      stops << Stop.new(destination:c, route:self, active:true, index:i+=1)
    }

    compute
  end

  def default_store
    stops.clear
    stops << Stop.new(destination:planning.customer.store, route:self, active:true, index:0)
    stops << Stop.new(destination:planning.customer.store, route:self, active:true, index:1)
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
      stops.sort{ |a,b| a.index <=> b.index }[1..-1].each{ |stop|
        destination = stop.destination
        if stop.active && destination.lat && destination.lng
          stop.distance, time, stop.trace = Trace.compute(last.destination.lat, last.destination.lng, destination.lat, destination.lng)
          stop.time = self.end + time
          if destination.open && stop.time < destination.open
            stop.time = destination.open
          end
          stop.out_of_window = (destination.open && stop.time < destination.open) || (destination.close && stop.time > destination.close)

          self.distance += stop.distance
          self.end = stop.time + (planning.customer.take_over ? planning.customer.take_over.seconds_since_midnight : 0)

          stop.out_of_capacity = destination != planning.customer.store && vehicle.capacity && quantity > vehicle.capacity
          quantity += (destination.quantity or 1)

          stop.out_of_drive_time = destination != planning.customer.store && stop.time > vehicle.close

          last = stop
        else
          stop.active = stop.out_of_capacity = stop.out_of_drive_time = false
          stop.distance = stop.trace = stop.time = nil
        end
        self.emission = self.distance / 1000 * vehicle.emission * vehicle.consumption / 100
      }
    end
  end

  def set_destinations(destinations)
    Stop.transaction do
      stops.clear
      destinations.select!{ |d| d[0] != planning.customer.store }
      if vehicle
        destinations = [[planning.customer.store, true]] + destinations + [[planning.customer.store, true]]
      end
      i = 0
      destinations.each{ |stop|
        destination, active = stop
        stops << Stop.new(destination:destination, route:self, active:active, index:i+=1)
      }
      compute
    end
  end

  def add(destination)
    stops << Stop.new(destination: destination, route: self)
    self.out_of_date = true
  end

  def remove(destination)
    stops.each{ |stop|
      if(stop.destination ==  destination)
        stop.destroy
        self.out_of_date = true
      end
    }
  end

  def matrix
    stops_on = stops_segregate[true]
    stops_on.collect{ |stop1|
      stops_on.collect{ |stop2|
        distance, time, trace = Trace.compute(stop1.destination.lat, stop1.destination.lng, stop2.destination.lat, stop2.destination.lng)
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
      stop.destination != planning.customer.store && (stop.active || ! vehicle) ? 1 : 0
    }
  end

  def quantity
    stops.to_a.sum(0) { |stop|
      stop.destination != planning.customer.store && (stop.active || ! vehicle) ? (stop.destination.quantity or 1) : 0
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

  private
    def assign_defaults
      self.hidden = false
      self.locked = false
    end

    def stops_segregate
      stops[0..-2].group_by{ |stop| !!(stop.active && stop.destination.lat && stop.destination.lng) }
    end

    def validate_stops_length
      if vehicle && stops.length > 100
        errors.add(:stops, :over_max_limit)
      end
    end
end
