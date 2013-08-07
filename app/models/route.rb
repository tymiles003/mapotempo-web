class Route < ActiveRecord::Base
  belongs_to :planning
  belongs_to :vehicle
end
