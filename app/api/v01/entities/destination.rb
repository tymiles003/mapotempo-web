class V01::Entities::Destination < Grape::Entity
  def self.entity_name
    'V01_Destination'
  end

  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:street, documentation: { type: String })
  expose(:postalcode, documentation: { type: String })
  expose(:city, documentation: { type: String })
  expose(:lat, documentation: { type: Float })
  expose(:lng, documentation: { type: Float })
  expose(:quantity, documentation: { type: Integer })
  expose(:open, documentation: { type: DateTime }) { |m| m.open && m.open.strftime('%H:%M:%S') }
  expose(:close, documentation: { type: DateTime }) { |m| m.close && m.close.strftime('%H:%M:%S') }
  expose(:detail, documentation: { type: String })
  expose(:comment, documentation: { type: String })
  expose(:ref, documentation: { type: String })
  expose(:take_over, documentation: { type: DateTime }) { |m| m.take_over && m.take_over.strftime('%H:%M:%S') }
  expose(:take_over_default, documentation: { type: DateTime }) { |m| m.customer && m.customer.take_over && m.customer.take_over.strftime('%H:%M:%S') }
  expose(:tag_ids, documentation: { type: Integer, is_array: true })
  expose(:geocoding_accuracy, documentation: { type: Float })
end
