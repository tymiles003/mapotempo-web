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
class Destination < Location
  has_many :visits, -> { order(:id) }, inverse_of: :destination, dependent: :delete_all, autosave: true
  accepts_nested_attributes_for :visits, allow_destroy: true
  validates_associated_bubbling :visits
  has_and_belongs_to_many :tags, after_add: :update_tags_track, after_remove: :update_tags_track

  auto_strip_attributes :name, :street, :postalcode, :city, :country, :detail, :comment, :phone_number

  before_save :update_tags

  include RefSanitizer

  amoeba do
    enable

    customize(lambda { |original, copy|
      def copy.update_tags; end
    })
  end

  def destroy
    # Too late to do this in before_destroy callback, children already destroyed
    Visit.transaction do
      visits.each{ |visit|
        visit.destroy
      }
    end
    super
  end

  def changed?
    @tags_updated || super
  end

  private

  def update_tags_track(_tag)
    @tags_updated = true
  end

  def update_tags
    if customer && (@tags_updated || new_record?)
      @tags_updated = false

      # Don't use local collection here, not set when save new record
      customer.plannings.each{ |planning|
        visits.select(&:id).each{ |visit|
          if planning.visits.include?(visit)
            if (planning.tags.to_a & (tags.to_a + visit.tags.to_a).uniq) != planning.tags.to_a
              planning.visit_remove(visit)
            end
          else
            if (planning.tags.to_a & (tags.to_a + visit.tags.to_a).uniq) == planning.tags.to_a
              planning.visit_add(visit)
            end
          end
        }
      }
    end

    true
  end

  def out_of_date
    Route.transaction do
      visits.each{ |visit|
        visit.out_of_date
      }
    end
  end
end
