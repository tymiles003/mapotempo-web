class Layer < ActiveRecord::Base
  validates :name, presence: true
  validates :url, presence: true
  validates :attribution, presence: true
end
