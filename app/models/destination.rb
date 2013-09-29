require 'geocode'

class Destination < ActiveRecord::Base
  belongs_to :customer
  has_many :stops, dependent: :destroy
  has_and_belongs_to_many :tags, after_add: :update_add_tag, after_remove: :update_remove_tag

#  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
  validates :city, presence: true
#  validates :lat, presence: true, numericality: {only_float: true}
#  validates :lng, presence: true, numericality: {only_float: true}

  before_update :update_out_of_date, :update_geocode
  before_destroy :destroy_out_of_date

  def geocode
    Rails.logger.info self.inspect
    address = Geocode.code(street, postalcode, city)
    Rails.logger.info address
    if address
      self.lat, self.lng = address[:lat], address[:lng]
    end
  end

  def reverse_geocode
    address = Geocoder.search([lat, lng])
    self.street, self.postalcode, self.city = address[0].street, address[0].postal_code, address[0].city
  end

  private
    def update_out_of_date
      if lat_changed? or lng_changed?
        out_of_date
      end
    end

    def update_geocode
      if street_changed? or postalcode_changed? or city_changed?
        geocode
      elsif lat_changed? or lng_changed?
        reverse_geocode
      end
    end

    def update_add_tag(tag)
      customer.plannings.select{ |planning|
        planning.tags.include?(tag)
      }.each{ |planning|
        planning.destination_add(self)
      }
    end

    def update_remove_tag(tag)
      customer.plannings.select{ |planning|
        planning.tags.include?(tag)
      }.each{ |planning|
        planning.destination_remove(self)
      }
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
