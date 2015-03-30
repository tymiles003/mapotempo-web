class V01::Entities::Order < Grape::Entity
  def self.entity_name
    'V01_Order'
  end

  expose(:id, documentation: { type: Integer })
  expose(:destination_id, documentation: { type: Integer })
  expose(:shift, documentation: { type: Integer })
  expose(:product_ids, documentation: { type: Integer, is_array: true })
end
