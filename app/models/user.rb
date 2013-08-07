class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :store, :class_name => "Destination"
  belongs_to :layer
  has_many :vehicles
  has_many :destinations
  has_many :plannings
  has_many :tags
end
