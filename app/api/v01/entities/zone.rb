class V01::Entities::Zone < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:vehicle_id, documentation: { type: 'Integer' })
  expose(:polygon, documentation: { type: 'Json' }) { |m| JSON.parse(m.polygon) }
end
