require 'trace'

class Route < ActiveRecord::Base
  belongs_to :planning
  belongs_to :vehicle
  has_many :stops, -> { order('"index"')}, :autosave => true, :dependent => :destroy

#  validates :planning, presence: true
#  validates :vehicle, presence: true

  after_initialize :assign_defaults, if: 'new_record?'

  def default_stops
    i = 0
    stops << Stop.create(destination:planning.user.store, route:self, active:true, index:0)
    planning.user.destinations.select{
      |c| c != planning.user.store
    }.select{ |c|
      planning.tags & c.tags == planning.tags
    }.each { |c|
      stops << Stop.create(destination:c, route:self, active:true, index:i+=1)
    }
    stops << Stop.create(destination:planning.user.store, route:self, active:true, index:i+=1)

    compute
  end

  def default_store
    stops << Stop.create(destination:planning.user.store, route:self, active:true, index:0)
    stops << Stop.create(destination:planning.user.store, route:self, active:true, index:1)
  end

  def compute
    self.out_of_date = false
    self.distance = 0
    self.emission = 0
    if vehicle
      last = stops[0]
      stops.sort{ |a,b| a.index <=> b.index }[1..-1].each{ |stop|
        if stop.active and stop.destination.lat and stop.destination.lng
          stop.distance, stop.trace = Trace.compute(last.destination.lat, last.destination.lng, stop.destination.lat, stop.destination.lng)
          self.distance += stop.distance
          last = stop
        else
          stop.active = false
          stop.begin = stop.end = stop.distance = stop.trace = nil
        end
      }
      self.emission = self.distance / 1000 * vehicle.emission * vehicle.consumption / 100
    end
  end

  def set_destinations(destinations)
    Stop.transaction do
      stops.clear
      if vehicle
        if destinations.size == 0 or destinations[0][0].id != planning.user.store.id
          destinations = [[planning.user.store, true]] + destinations
        end
        if destinations[-1][0].id != planning.user.store.id
          destinations << [planning.user.store, true]
        end
      end
      i = 0
      destinations.each{ |stop|
        destination, active = stop
        stops << Stop.create(destination:destination, route:self, active:active, index:i+=1)
      }
      compute
    end
  end

  private
    def assign_defaults
      self.hidden = false
      self.locked = false
    end
end
