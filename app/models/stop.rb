class Stop < ActiveRecord::Base
  belongs_to :route
  belongs_to :destination

#  validates :route, presence: true
#  validates :destination, presence: true
end
