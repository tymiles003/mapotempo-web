class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :customer, :autosave => true
  belongs_to :layer

  after_initialize :assign_defaults, if: 'new_record?'

  private
    def assign_defaults
      self.layer_id = 1
    end
end
