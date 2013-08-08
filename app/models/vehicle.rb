class Vehicle < ActiveRecord::Base
  belongs_to :user
  has_many :routes, :autosave => true

#  validates :user, presence: true
  validates :name, presence: true
  validates :emission, presence: true, numericality: {only_float: true}
  validates :consumption, presence: true, numericality: {only_float: true}
  validates :capacity, presence: true, numericality: {only_integer: true}
  validates :color, presence: true

  after_initialize :assign_defaults, if: 'new_record?'
  before_update :update_out_of_date

  def self.emissions_table
  [
    ["Rien - 0", "0"],
    ["Essence - 2,71", "2.71"],
    ["Gazole - 3,07", "3.07"],
    ["GPL - 1,77", "1.77"],
  ]
  end

  def self.colors_table
    ["004499", "EEEE00", "00CC00", "DD0000", "EEEEBB", "558800", "FFBB00", "00BBFF"]
  end

  private
    def assign_defaults
      self.emission = 0
      self.consumption = 0
      self.capacity = 999
      self.color = Vehicle.colors_table[0]
    end

    def update_out_of_date
      if emission_changed? or consumption_changed? or capacity_changed?
        routes.each{ |route|
          route.out_of_date = true
        }
      end
    end
end
