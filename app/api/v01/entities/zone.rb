class V01::Entities::Zone < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:vehicle_ids, documentation: { type: 'Array' }) { |m| m.vehicles.collect &:id }
  expose(:polygon, documentation: { type: 'Json' }) { |m| JSON.parse(m.polygon) }
end
