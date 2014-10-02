class V01::Entities::Customer < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:end_subscription, documentation: { type: 'Date' })
  expose(:max_vehicles, documentation: { type: 'Integer' })
  expose(:take_over, documentation: { type: 'DateTime' }) { |m| m.take_over && m.take_over.strftime('%H:%M:%S') }
  expose(:store_ids, documentation: { type: 'Array' }) { |m| m.stores.collect(&:id) }
  expose(:job_geocoding_id, documentation: { type: 'Integer' })
  expose(:job_matrix_id, documentation: { type: 'Integer' })
  expose(:job_optimizer_id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:tomtom_user, documentation: { type: 'String' })
  expose(:tomtom_password, documentation: { type: 'String' })
  expose(:tomtom_account, documentation: { type: 'String' })
  expose(:router_id, documentation: { type: 'Integer' })
  expose(:print_planning_annotating, documentation: { type: 'Integer' })
  expose(:print_header, documentation: { type: 'String' })
end
