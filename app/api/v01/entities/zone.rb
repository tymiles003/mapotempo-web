class V01::Entities::Zone < Grape::Entity
  def self.entity_name
    'V01_Zone'
  end

  expose(:id, documentation: { type: Integer })
  expose(:vehicle_id, documentation: { type: Integer })
  expose(:polygon, documentation: { type: 'GeoJson' }) { |m| JSON.parse(m.polygon) }
end
