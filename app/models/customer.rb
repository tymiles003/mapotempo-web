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
class Customer < ActiveRecord::Base
  belongs_to :router
  belongs_to :store, :class_name => "Destination", :autosave => true, :dependent => :destroy
  belongs_to :job_geocoding, :class_name => "Delayed::Backend::ActiveRecord::Job", :dependent => :destroy
  belongs_to :job_matrix, :class_name => "Delayed::Backend::ActiveRecord::Job", :dependent => :destroy
  belongs_to :job_optimizer, :class_name => "Delayed::Backend::ActiveRecord::Job", :dependent => :destroy
  has_many :vehicles, -> { order('id')}, inverse_of: :customer, :autosave => true, :dependent => :destroy
  has_many :destinations, -> { order('id')}, inverse_of: :customer, :autosave => true, :dependent => :destroy
  has_many :plannings, -> { order('id')}, inverse_of: :customer, :autosave => true, :dependent => :destroy
  has_many :tags, -> { order('label')}, inverse_of: :customer, :autosave => true, :dependent => :destroy
  has_many :users, inverse_of: :customer
  has_many :zonings, inverse_of: :customer, :dependent => :destroy

  nilify_blanks
  validates :router, presence: true
  validates :name, presence: true
  validates :destinations, length: { maximum: 2000, message: :over_max_limit }

  after_initialize :assign_defaults, if: 'new_record?'
  before_create :update_max_vehicles
  before_update :update_out_of_date, :update_max_vehicles

  private
    def assign_defaults
      self.store = Destination.create(
        name: I18n.t('destinations.default_store_name'),
        city: I18n.t('destinations.default_store_city'),
        lat: Float(I18n.t('destinations.default_store_lat')),
        lng: Float(I18n.t('destinations.default_store_lng'))
      )
    end

    def update_out_of_date
      if take_over_changed?
        Route.transaction do
          plannings.each{ |planning|
            planning.routes.each{ |route|
              route.out_of_date = true
            }
          }
        end
      end
    end

    def update_max_vehicles
      if max_vehicles_changed?
        if vehicles.size < max_vehicles
          # Add new
          (max_vehicles - vehicles.size).times{ |i|
            vehicle = vehicles.build(name: I18n.t('vehicles.default_name', n:vehicles.size+1))
            plannings.each{ |planning|
              planning.vehicle_add(vehicle)
            }
          }
        elsif vehicles.size > max_vehicles
          # Delete
          (vehicles.size - max_vehicles).times{ |i|
            vehicle = vehicles[vehicles.size-i-1]
            plannings.each{ |planning|
              planning.vehicle_remove(vehicle)
            }
            vehicle.destroy
          }
        end
      end
    end
end
