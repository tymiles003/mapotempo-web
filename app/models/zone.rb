class Zone < ActiveRecord::Base
  belongs_to :zoning
  has_and_belongs_to_many :vehicles
end
