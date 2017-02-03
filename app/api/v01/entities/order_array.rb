class V01::Entities::OrderArray < Grape::Entity
  def self.entity_name
    'V01_OrderArray'
  end

  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:base_date, documentation: { type: Date })
  expose(:length, documentation: { type: String, values: ::OrderArray.lengths.keys })
  expose(:orders, using: V01::Entities::Order, documentation: { type: V01::Entities::Order, is_array: true })
end
