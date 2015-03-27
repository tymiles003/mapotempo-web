class V01::Entities::Tag < Grape::Entity
  expose(:id, documentation: { type: Integer })
  expose(:label, documentation: { type: String })
  expose(:color, documentation: { type: String })
  expose(:icon, documentation: { type: String, values: ::Tag.icons_table })
end
