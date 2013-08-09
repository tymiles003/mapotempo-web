class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :store, :class_name => "Destination"
  belongs_to :layer
  has_many :vehicles, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :destinations, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :plannings, -> { order('id')}, :autosave => true, :dependent => :destroy
  has_many :tags, -> { order('label')}, :autosave => true, :dependent => :destroy

  before_update :update_out_of_date

  private
    def update_out_of_date
      if take_over_changed?
        Route.transaction do
          plannings.each{ |planning|
            planning.routes.each{ |route|
              route.out_of_date = true
            }
          }
        end
      end
    end
end
