class Destination < ActiveRecord::Base
  belongs_to :user
  has_many :stops, :dependent => :destroy
  has_and_belongs_to_many :tags, -> { order('label')}

#  validates :user, presence: true
  validates :name, presence: true
#  validates :street, presence: true
  validates :city, presence: true
#  validates :lat, presence: true, numericality: {only_float: true}
#  validates :lng, presence: true, numericality: {only_float: true}

  before_update :update_out_of_date
  before_destroy :destroy_out_of_date

  private
    def update_out_of_date
      if lat_changed? or lng_changed?
        out_of_date
      end
    end

    def destroy_out_of_date
      out_of_date
    end

    def out_of_date
      Route.transaction do
        stops.each{ |stop|
          stop.route.out_of_date = true
          stop.route.save
        }
      end
    end
end
