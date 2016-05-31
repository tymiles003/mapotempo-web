# Copyright © Mapotempo, 2016
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
class Visit < ActiveRecord::Base
  belongs_to :destination
  has_many :stop_visits, inverse_of: :visit, dependent: :delete_all
  has_many :orders, inverse_of: :visit, dependent: :delete_all
  has_and_belongs_to_many :tags, after_add: :update_tags_track, after_remove: :update_tags_track
  delegate :lat, :lng, :name, :street, :postalcode, :city, :country, :detail, :comment, :phone_number, to: :destination

  nilify_blanks
  validates :destination, presence: true
  validates_time :open, if: :open
  validates_time :close, presence: false, on_or_after: :open, if: :close

  before_save :update_tags, :create_orders
  before_update :update_out_of_date

  include RefSanitizer

  amoeba do
    exclude_association :stop_visits
    exclude_association :orders

    customize(lambda { |original, copy|
      def copy.update_tags; end
      def copy.create_orders; end
      def copy.update_out_of_date; end
    })
  end

  include LocalizedAttr

  attr_localized :quantity

  def destroy
    # Too late to do this in before_destroy callback, children already destroyed
    Route.transaction do
      stop_visits.each{ |stop|
        stop.route.remove_stop(stop)
        stop.route.save
      }
    end
    super
  end

  def changed?
    @tags_updated || super
  end

  def out_of_date
    Route.transaction do
      stop_visits.each{ |stop|
        stop.route.out_of_date = true
        stop.route.save
      }
    end
  end

  private

  def update_out_of_date
    if open_changed? || close_changed? || quantity_changed? || take_over_changed?
      out_of_date
    end
  end

  def update_tags_track(_tag)
    @tags_updated = true
  end

  def update_tags
    if destination.customer && (@tags_updated || new_record?)
      @tags_updated = false

      # Don't use local collection here, not set when save new record
      destination.customer.plannings.each{ |planning|
        if planning.visits.include?(self)
          if (planning.tags.to_a & (tags.to_a | destination.tags.to_a)) != planning.tags.to_a
            planning.visit_remove(self)
          end
        else
          if (planning.tags.to_a & (tags.to_a | destination.tags.to_a)) == planning.tags.to_a
            planning.visit_add(self)
          end
        end
      }
    end

    true
  end

  def create_orders
    if destination.customer && new_record?
      destination.customer.order_arrays.each{ |order_array|
        order_array.add_visit(self)
      }
    end
  end
end
