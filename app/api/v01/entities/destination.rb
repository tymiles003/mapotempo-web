class V01::Entities::Destination < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:street, documentation: { type: 'String' })
  expose(:postalcode, documentation: { type: 'String' })
  expose(:city, documentation: { type: 'String' })
  expose(:lat, documentation: { type: 'Decimal' })
  expose(:lng, documentation: { type: 'Decimal' })
  expose(:quantity, documentation: { type: 'Integer' })
  expose(:open) { |m| m.open && m.open.strftime('%H:%M') }
  expose(:close) { |m| m.close && m.close.strftime('%H:%M') }
  expose(:detail, documentation: { type: 'String' })
  expose(:comment, documentation: { type: 'String' })
  expose(:ref, documentation: { type: 'String' })
  expose(:take_over, documentation: { type: 'DateTime' }) { |m| m.take_over && m.take_over.strftime('%H:%M:%S') }
  expose(:take_over_default, documentation: { type: 'DateTime' }) { |m| m.customer && m.customer.take_over && m.customer.take_over.strftime('%H:%M:%S') }
  expose(:tag_ids, documentation: { type: 'Array' }) { |m| m.tags.collect &:id }
end
