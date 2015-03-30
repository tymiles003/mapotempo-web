class V01::Entities::Product < Grape::Entity
  def self.entity_name
    'V01_Product'
  end

  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:code, documentation: { type: String })
end
