class V01::Entities::Planning < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:ref, documentation: { type: 'String' })
  expose(:date, documentation: { type: 'Date' })
  expose(:zoning_id, documentation: { type: 'Integer' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:route_ids, documentation: { type: 'Array' }) { |m| m.routes.collect(&:id) }
  expose(:tag_ids, documentation: { type: 'Array' }) { |m| m.tags.collect(&:id) }
end
