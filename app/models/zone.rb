class Zone < ActiveRecord::Base
  belongs_to :zoning, touch: true
  has_and_belongs_to_many :vehicles

  validate :valide_vehicles_from_customer

  def inside?(lat, lng)
    point = RGeo::Cartesian.factory.point(lng, lat)
    (@geom || decode_geom).geometry().contains?(point)
  end

  private
    def decode_geom
      @geom = RGeo::GeoJSON.decode(polygon, :json_parser => :json)
    end

    def valide_vehicles_from_customer
      vehicles.each { |vehicle|
        if vehicle.customer != zoning.customer
          errors.add(:vehicles, :bad_customer)
          return
        end
      }
    end
end
