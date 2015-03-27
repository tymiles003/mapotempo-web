class V01::Entities::Route < Grape::Entity
  expose(:id, documentation: { type: Integer })
  expose(:distance, documentation: { type: Float })
  expose(:emission, documentation: { type: Float })
  expose(:vehicle_id, documentation: { type: Integer })
  expose(:start, documentation: { type: DateTime } ) { |m| m.start && m.start.strftime('%H:%M') }
  expose(:end, documentation: { type: DateTime } ) { |m| m.end && m.end.strftime('%H:%M') }
  expose(:hidden, documentation: { type: 'Boolean' })
  expose(:locked, documentation: { type: 'Boolean' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:stops, using: V01::Entities::Stop, documentation: { type: V01::Entities::Stop, is_array: true })
  expose(:stop_trace, documentation: { type: String })
  expose(:stop_out_of_drive_time, documentation: { type: 'Boolean' })
  expose(:stop_distance, documentation: { type: Float })
  expose(:ref, documentation: { type: String })
end
