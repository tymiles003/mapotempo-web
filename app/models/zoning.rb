class Zoning < ActiveRecord::Base
  belongs_to :customer
  has_many :zones, dependent: :destroy, autosave: true

  validates :name, presence: true

  def set_zones(zones)
    self.zones.clear
    zones and zones.each{ |zone|
      self.zones << Zone.new(zone)
    }
  end
end
