class V01::Entities::Route < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:distance, documentation: { type: 'Float' })
  expose(:emission, documentation: { type: 'Float' })
  expose(:vehicle_id, documentation: { type: 'Integer' })
  expose(:start, documentation: { type: 'DateTime' } ) { |m| m.start and m.start.strftime('%H:%M') }
  expose(:end, documentation: { type: 'DateTime' } ) { |m| m.end and m.end.strftime('%H:%M') }
  expose(:hidden, documentation: { type: 'Boolean' })
  expose(:locked, documentation: { type: 'Boolean' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:stops, using: V01::Entities::Stop, documentation: { type: 'Json' })
end
