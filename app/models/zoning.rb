class Zoning < ActiveRecord::Base
  belongs_to :customer
  has_many :zones, dependent: :destroy, autosave: true
  has_many :plannings, dependent: :nullify, autosave: true

  accepts_nested_attributes_for :zones, allow_destroy: true
  validates_associated_bubbling :zones

  validates :name, presence: true

  def apply(destinations)
    destinations.group_by{ |destination|
      zones.find{ |zone|
        zone.inside?(destination.lat, destination.lng)
      }
    }
  end
end
