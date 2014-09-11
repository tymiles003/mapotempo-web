class V01::Entities::Vehicle < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:emission, documentation: { type: 'Integer' })
  expose(:consumption, documentation: { type: 'Integer' })
  expose(:capacity, documentation: { type: 'Integer' })
  expose(:color, documentation: { type: 'String' })
  expose(:open, documentation: { type: DateTime }) { |m| m.open && m.open.strftime('%H:%M:%S') }
  expose(:close, documentation: { type: DateTime }) { |m| m.close && m.close.strftime('%H:%M:%S') }
  expose(:tomtom_id, documentation: { type: 'String' })
end
