class V01::Entities::Product < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:code, documentation: { type: 'String' })
end
