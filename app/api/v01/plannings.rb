class V01::Plannings < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def planning_params
      p = ActionController::Parameters.new(params)
      p = p[:planning] if p.key?(:planning)
      p.permit(:name, :ref, :date, :zoning_id, tag_ids: [])
    end

    Id_desc = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :plannings do
    desc 'Fetch customer\'s plannings.', {
      nickname: 'getPlannings'
    }
    get do
      present current_customer.plannings.load, with: V01::Entities::Planning
    end

    desc 'Fetch planning.', {
      nickname: 'getPlanning'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    get ':id' do
      id = read_id(params[:id])
      present current_customer.plannings.where(id).first, with: V01::Entities::Planning
    end

    desc 'Create planning.', {
      nickname: 'createPlanning',
      params: V01::Entities::Planning.documentation.except(:id).merge({
        name: { required: true }
      })
    }
    post  do
      planning = current_customer.plannings.build(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Update planning.', {
      nickname: 'updatePLanning',
      params: V01::Entities::Planning.documentation.except(:id)
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    put ':id' do
      id = read_id(params[:id])
      planning = current_customer.plannings.where(id).first
      planning.update(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Delete planning.', {
      nickname: 'deletePlanning'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    delete ':id' do
      id = read_id(params[:id])
      current_customer.plannings.where(id).first.destroy
    end

    desc 'Force recompute the planning after parameter update.', {
      nickname: 'refreshPlanning'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    get ':id/refresh' do
      id = read_id(params[:id])
      planning = current_customer.plannings.where(id).first
      planning.compute
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Switch two vehicles.', {
      nickname: 'switchVehicles'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    patch ':id/switch' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Suggest a place for an unaffected destination.', {
      nickname: 'automaticInsertDestination'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    patch ':id/automatic_insert' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Set stop status.', {
      nickname: 'updateStop'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    patch ':id/update_stop' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Starts asynchronous routes optimization.', {
      nickname: 'optimizeRoutes'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    get ':id/optimize_each_routes' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc 'Clone the planning.', {
      nickname: 'clonePlanning'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    patch ':id/duplicate' do
      id = read_id(params[:id])
      planning = current_customer.plannings.where(id).first
      planning = planning.amoeba_dup
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc 'Use order_array in the planning.', {
      nickname: 'useOrderArray'
    }
    params {
      requires :id, type: String, desc: Id_desc
      requires :order_array_id, type: String
      requires :shift, type: Integer
    }
    patch ':id/orders/:order_array_id/:shift' do
      id = read_id(params[:id])
      planning = current_customer.plannings.where(id).first
      order_array = current_customer.order_arrays.find(params[:order_array_id])
      shift = params[:shift].to_i
      planning.apply_orders(order_array, shift)
      planning.save!
      present planning, with: V01::Entities::Planning
    end
  end
end
