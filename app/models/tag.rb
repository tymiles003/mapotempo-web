class Tag < ActiveRecord::Base
  belongs_to :customer
  has_and_belongs_to_many :destinations
  has_and_belongs_to_many :plannings

#  validates :customer, presence: true
end
