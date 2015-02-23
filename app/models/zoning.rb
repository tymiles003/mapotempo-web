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
  validates :name, presence: true

  before_create :update_out_of_date
  before_save :update_out_of_date

  amoeba do
    enable
    exclude_association :plannings

    customize(lambda { |original, copy|
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
    zones.find{ |zone|
      zone.inside?(destination.lat, destination.lng)
    }
  end

  def flag_out_of_date
    plannings.each{ |planning|
      planning.zoning_out_of_date = true
    }
  end

  private

  def update_out_of_date
    if @collection_touched
      flag_out_of_date
    end
  end

  def touch_zones(zone)
    @collection_touched = true
  end
end
