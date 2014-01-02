class Stop < ActiveRecord::Base
  belongs_to :route, touch: true
  belongs_to :destination

#  validates :route, presence: true
#  validates :destination, presence: true
end
