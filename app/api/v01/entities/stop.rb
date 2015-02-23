class V01::Entities::Stop < Grape::Entity
  expose(:index, documentation: { type: 'Integer' })
  expose(:active, documentation: { type: 'Boolean' })
  expose(:distance, documentation: { type: 'Float' })
  expose(:trace, documentation: { type: 'String' })
  expose(:destination_id, documentation: { type: 'Integer' })
  expose(:wait_time, documentation: { type: 'DateTime' }) { |m| m.wait_time && ('%i:%02i' % [m.wait_time / 60 / 60, m.wait_time / 60 % 60]) }
  expose(:time, documentation: { type: 'DateTime' }) { |m| m.time && m.time.strftime('%H:%M') }
  expose(:out_of_window, documentation: { type: 'Boolean' })
  expose(:out_of_capacity, documentation: { type: 'Boolean' })
  expose(:out_of_drive_time, documentation: { type: 'Boolean' })
end
