class V01::Entities::Store < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:street, documentation: { type: 'String' })
  expose(:postalcode, documentation: { type: 'String' })
  expose(:city, documentation: { type: 'String' })
  expose(:lat, documentation: { type: 'Decimal' })
  expose(:lng, documentation: { type: 'Decimal' })
  expose(:open) { |m| m.open && m.open.strftime('%H:%M') }
  expose(:close) { |m| m.close && m.close.strftime('%H:%M') }
end
