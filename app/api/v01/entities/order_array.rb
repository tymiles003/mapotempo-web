class V01::Entities::OrderArray < Grape::Entity
  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:base_date, documentation: { type: Date })
  expose(:length, documentation: { type: Integer })
  expose(:orders, using: V01::Entities::Order, documentation: { type: V01::Entities::Order, is_array: true })
end
