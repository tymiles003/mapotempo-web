class V01::Entities::Customer < Grape::Entity
  def self.entity_name
    'V01_Customer'
  end

  expose(:id, documentation: { type: Integer })
  expose(:end_subscription, documentation: { type: Date })
  expose(:max_vehicles, documentation: { type: Integer })
  expose(:take_over, documentation: { type: DateTime }) { |m| m.take_over && m.take_over.strftime('%H:%M:%S') }
  expose(:store_ids, documentation: { type: Integer, is_array: true })
  expose(:job_geocoding_id, documentation: { type: Integer })
  expose(:job_optimizer_id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:tomtom_user, documentation: { type: String })
  expose(:tomtom_password, documentation: { type: String })
  expose(:tomtom_account, documentation: { type: String })
  expose(:masternaut_user, documentation: { type: String })
  expose(:masternaut_password, documentation: { type: String })
  expose(:router_id, documentation: { type: Integer })
  expose(:print_planning_annotating, documentation: { type: Integer })
  expose(:print_header, documentation: { type: String })
  expose(:alyacom_association, documentation: { type: String })
  # hidden admin only field :enable_orders, :test, :optimization_cluster_size, :optimization_time, :optimization_soft_upper_bound
end
