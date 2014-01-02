class Zone < ActiveRecord::Base
  belongs_to :zoning, touch: true
  has_and_belongs_to_many :vehicles

  def inside?(lat, lng)
    point = RGeo::Cartesian.factory.point(lng, lat)
    (@geom || decode_geom).geometry().contains?(point)
  end

  private
    def decode_geom
      @geom = RGeo::GeoJSON.decode(polygon, :json_parser => :json)
    end
end
