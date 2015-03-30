class V01::Entities::Planning < Grape::Entity
  def self.entity_name
    'V01_Planning'
  end

  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:ref, documentation: { type: String })
  expose(:date, documentation: { type: Date })
  expose(:zoning_id, documentation: { type: Integer })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:route_ids, documentation: { type: Integer, is_array: true })
  expose(:tag_ids, documentation: { type: Integer, is_array: true })
end
