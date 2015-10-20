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
    clusters = planning.routes.select(&:vehicle).collect{ |route|
      route.stops.select{ |stop| stop.is_a?(StopDestination) }.collect{ |stop|
        if stop.position?
          [stop.lat, stop.lng]
        end
      }.compact.uniq
    }
    vehicles = planning.routes.select(&:vehicle).collect(&:vehicle)
    Clustering.hulls(clusters).each{ |hull|
      vehicle = vehicles.shift
      if hull
        zones.build({polygon: hull, vehicle: vehicle})
      end
    }
  end

  def isochrone?
    isowhat?(:isochrone?)
  end

  def isochrone(size, store_id = nil)
    if store_id
      isowhat_store(:isochrone?, :isochrone, size, customer.stores.find(store_id))
    else
      isowhat(:isochrone?, :isochrone, size)
    end
  end

  def isodistance?
    isowhat?(:isodistance?)
  end

  def isodistance(size, store_id = nil)
    if store_id
      isowhat_store(:isodistance?, :isodistance, size, customer.stores.find(store_id))
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
    customer.stores.each{ |store|
      isowhat_store(what_qm, what, size, store)
    }
  end

  def isowhat_store(what_qm, what, size, store)
    if store
      if customer.router.method(what_qm).call && !store.lat.nil? && !store.lng.nil?
        geom = customer.router.method(what).call(store.lat, store.lng, size, customer.speed_multiplicator || 1)
      end
      if geom
        zone = zones.where({store_id: store.id}).first
        if zone
          zone.polygon = geom
        else
          zones.build({polygon: geom, store: store})
        end
      end
    end
  end
end
