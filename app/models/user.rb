class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :store, :class_name => "Destination"
  belongs_to :layer
  has_many :vehicles, -> { order('id')}
  has_many :destinations, -> { order('id')}
  has_many :plannings, -> { order('id')}
  has_many :tags, -> { order('label')}
end
