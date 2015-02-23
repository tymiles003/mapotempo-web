class V01::Plannings < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def planning_params
      p = ActionController::Parameters.new(params)
      p = p[:planning] if p.has_key?(:planning)
      p.permit(:name, :zoning_id, :tag_ids => [])
    end
  end

  resource :plannings do
    desc "Return customer's plannings."
    get do
      present current_customer.plannings.load, with: V01::Entities::Planning
    end

    desc 'Return a planning.'
    get ':id' do
      present current_customer.plannings.find(params[:id]), with: V01::Entities::Planning
    end

    desc 'Create a planning.', {
      params: V01::Entities::Planning.documentation.except(:id)
    }
    post  do
      planning = current_customer.plannings.build(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Update a planning.', {
      params: V01::Entities::Planning.documentation.except(:id)
    }
    put ':id' do
      planning = current_customer.plannings.find(params[:id])
      planning.update(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Destroy a planning.'
    delete ':id' do
      current_customer.plannings.find(params[:id]).destroy
    end

    desc 'Force recompute the planning after parameter update.'
    get ':id/refresh' do
      planning = current_customer.plannings.find(params[:id])
      planning.compute
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Switch two vehicles.'
    patch ':id/switch' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Suggest a place for an unaffected destination.'
    patch ':id/automatic_insert' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Set stop status.'
    patch ':id/update_stop' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Starts asynchronous routes optimization.'
    get ':id/optimize_each_routes' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Clone the planning.'
    patch ':id/duplicate' do
      planning = current_customer.plannings.find(params[:id])
      planning = planning.amoeba_dup
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Use order_array in the planning.'
    patch ':id/orders/:order_array_id/:shift' do
      planning = current_customer.plannings.find(params[:id])
      order_array = current_customer.order_arrays.find(params[:order_array_id])
      shift = params[:shift].to_i
      planning.apply_orders(order_array, shift)
      planning.save!
      present planning, with: V01::Entities::Planning
    end
  end
end
