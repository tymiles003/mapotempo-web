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
class Zoning < ActiveRecord::Base
  belongs_to :customer
  has_many :zones, inverse_of: :zoning, dependent: :delete_all, autosave: true, after_add: :touch_zones, after_remove: :touch_zones
  has_many :plannings, inverse_of: :zoning, dependent: :nullify, autosave: true

  accepts_nested_attributes_for :zones, allow_destroy: true
  validates_associated_bubbling :zones

  nilify_blanks
  auto_strip_attributes :name
  validates :name, presence: true

  before_create :update_out_of_date
  before_save :update_out_of_date

  amoeba do
    enable
    exclude_association :plannings

    customize(lambda { |_original, copy|
      copy.zones.each{ |zone|
        zone.zoning = copy
      }
    })

    append name: Time.now.strftime(' %Y-%m-%d %H:%M')
  end

  def apply(destinations)
    destinations.group_by{ |destination|
      inside(destination)
    }
  end

  # Return the zone corresponding to destination location
  def inside(destination)
    z = zones.collect{ |zone|
      [zone, zone.inside_distance(destination.lat, destination.lng)]
    }.select{ |zone, d|
      d
    }.max_by{ |zone, d|
      d
    }
    z[0] if z
  end

  def flag_out_of_date
    plannings.each{ |planning|
      planning.zoning_out_of_date = true
    }
  end

  def automatic_clustering(planning, n)
    positions = planning.routes.collect{ |route| route.stops }.flatten.collect{ |stop|
      if stop.position?
        [stop.lat, stop.lng]
      end
    }.compact.uniq

    vehicles = planning.customer.vehicles.to_a
    clusters = Clustering.clustering(positions, n || vehicles.size)
    zones.clear
    Clustering.hulls(clusters).each{ |hull|
      zones.build({polygon: hull, vehicle: vehicles.shift})
    }
  end

  def from_planning(planning)
    zones.clear
    clusters = planning.routes.select(&:vehicle_usage).collect{ |route|
      route.stops.select{ |stop| stop.is_a?(StopDestination) }.collect{ |stop|
        if stop.position?
          [stop.lat, stop.lng]
        end
      }.compact.uniq
    }
    vehicle_usages = planning.routes.select(&:vehicle_usage).collect(&:vehicle_usage)
    Clustering.hulls(clusters).each{ |hull|
      vehicle_usage = vehicle_usages.shift
      if hull
        zones.build({polygon: hull, vehicle: vehicle_usage.vehicle})
      end
    }
  end

  def isochrone?
    isowhat?(:isochrone?)
  end

  def isochrone(size, vehicle_id = nil)
    if vehicle_id
      isowhat(:isochrone?, :isochrone, size, customer.vehicles.find(vehicle_id))
    else
      isowhat(:isochrone?, :isochrone, size)
    end
  end

  def isodistance?
    isowhat?(:isodistance?)
  end

  def isodistance(size, vehicle_id = nil)
    if vehicle_id
      isowhat_vehicle(:isodistance?, :isodistance, size, customer.vehicles.find(vehicle_id))
    else
      isowhat(:isodistance?, :isodistance, size)
    end
  end

  private

  def update_out_of_date
    if @collection_touched
      flag_out_of_date
    end
  end

  def touch_zones(_zone)
    @collection_touched = true
  end

  def isowhat?(what)
    customer.vehicles.find{ |vehicle|
      router = (vehicle.router || customer.router)
      router.method(what).call && !vehicle.store_start.nil? && !vehicle.store_start.lat.nil? && !vehicle.store_start.lng.nil?
    }
  end

  def isowhat(what_qm, what, size)
    zones.clear
    customer.vehicles.each{ |vehicle|
      isowhat_vehicle(what_qm, what, size, vehicle)
    }
  end

  def isowhat_vehicle(what_qm, what, size, vehicle)
    if vehicle
      router = (vehicle.router || customer.router)
      if router.method(what_qm).call && !vehicle.store_start.nil? && !vehicle.store_start.lat.nil? && !vehicle.store_start.lng.nil?
        geom = router.method(what).call(vehicle.store_start.lat, vehicle.store_start.lng, size, (customer.speed_multiplicator || 1) * (vehicle.speed_multiplicator || 1))
      end
      if geom
        zone = zones.where({vehicle_id: vehicle.id}).first
        if zone
          zone.polygon = geom
        else
          zones.build({polygon: geom, vehicle: vehicle})
        end
      end
    end
  end
end
