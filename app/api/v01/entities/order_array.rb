class V01::Entities::OrderArray < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:base_date, documentation: { type: 'DateTime' } ) { |m| m.base_date and m.base_date.strftime('%H:%M') }
  expose(:length, documentation: { type: 'Integer' })
  expose(:orders, using: V01::Entities::Order, documentation: { type: 'Json' })
end
