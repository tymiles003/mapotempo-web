class V01::Entities::Tag < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:label, documentation: { type: 'String' })
end
