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
class Planning < ActiveRecord::Base
  belongs_to :customer
  belongs_to :zoning
  has_many :routes, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_and_belongs_to_many :tags, -> { order('label')}, :autosave => true

#  validates :customer, presence: true
  validates :name, presence: true

  before_create :update_zoning
  before_update :update_zoning

  def set_destinations(destinations)
    default_empty_routes
    routes[0].set_destinations([])
    if destinations.size <= routes.size-1
      0.upto(destinations.size-1).each{ |i|
        routes[i+1].set_destinations(destinations[i].collect{ |d| [d, true] })
      }
    else
      raise I18n.t('errors.planning.import_too_routes')
   end
  end

  def vehicle_add(vehicle)
    route = Route.new(planning: self, vehicle: vehicle, out_of_date:true)
    route.default_store
    routes << route
  end

  def vehicle_remove(vehicle)
    route = routes.find{ |route| route.vehicle == vehicle }
    routes[0].stops += route.stops.select{ |stop| stop.destination != customer.store }.collect{ |stop| Stop.new(destination: stop.destination, route: route[0]) }
    routes[0].out_of_date = true
    route.destroy
  end

  def destination_add(destination)
    routes[0].add(destination)
  end

  def destination_remove(destination)
    routes.each{ |route|
      route.remove(destination)
    }
  end

  def default_empty_routes
    routes << Route.new(planning: self)
    customer.vehicles.each { |vehicle|
      vehicle_add(vehicle)
    }
  end

  def default_routes
    default_empty_routes
    routes[0].default_stops
  end

  def compute
    if zoning && updated_at < zoning.updated_at
      split_by_zones
      self.touch # Force update date for no more on out_of_date without waiting for before_update
    end
    routes.each(&:compute)
  end

  def switch(route, vehicle)
    route_prec = routes.find{ |route| route.vehicle == vehicle }
    if route_prec
      vehicle_prec = route.vehicle
      route.vehicle = vehicle
      route_prec.vehicle = vehicle_prec
    else
      false
    end
  end

  def out_of_date
    (zoning && updated_at < zoning.updated_at) || routes.inject(false){ |acc, route|
      acc or route.out_of_date
    }
  end

  def active_all
    routes.each(&:active_all)
  end

  def destinations
    customer.destinations.select{ |c|
      c != customer.store
    }.select{ |c|
      tags & c.tags == tags
    }
  end

  private
    def split_by_zones
      z = {}
      unaffected = []
      zoning.apply(destinations).each{ |zone, destinations|
        if zone && zone.vehicles && zone.vehicles.size > 0
          z[zone.vehicles[0]] = destinations
        else
          unaffected += destinations
        end
      }
      z = Hash[z]
      routes[0].set_destinations(unaffected)
      routes[1..-1].each{ |route|
        if route.vehicle && z.has_key?(route.vehicle)
          route.set_destinations(z[route.vehicle].collect{ |d| [d,true]})
        else
          route.set_destinations([])
        end
        route.out_of_date = true
      }
    end

    def update_zoning
      if zoning && zoning_id_changed?
        split_by_zones
      end
    end
end
