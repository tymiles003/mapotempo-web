class V01::OrderArrays < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_array_params
      p = ActionController::Parameters.new(params)
      p = p[:order_array] if p.key?(:order_array)
      p.permit(:name, :base_date, :length)
    end

    def authorize!
      ability = Ability.new(@current_user)
      error!('401 Unauthorized', 401) unless ability.can?(:manage, OrderArray)
    end
  end

  resource :order_arrays do
    desc 'Fetch customer''s order_arrays.', {
      nickname: 'getOrderArrays'
    }
    get do
      present current_customer.order_arrays.load, with: V01::Entities::OrderArray
    end

    desc 'Fetch order_array.', {
      nickname: 'getOrderArray'
    }
    get ':id' do
      present current_customer.order_arrays.find(params[:id]), with: V01::Entities::OrderArray
    end

    desc 'Create order_array.', {
      nickname: 'createOrderArray',
      params: V01::Entities::OrderArray.documentation.except(:id)
    }
    post  do
      order_array = current_customer.order_arrays.build(order_array_params)
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Update order_array.', {
      nickname: 'updateOrderArray',
      params: V01::Entities::OrderArray.documentation.except(:id)
    }
    put ':id' do
      order_array = current_customer.order_arrays.find(params[:id])
      order_array.update(order_array_params)
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Delete order_array.', {
      nickname: 'deleteOrderArray'
    }
    delete ':id' do
      current_customer.order_arrays.find(params[:id]).destroy
    end

    desc 'Clone the order_array.', {
      nickname: 'cloneOrderArray'
    }
    patch ':id/duplicate' do
      order_array = current_customer.order_arrays.find(params[:id])
      order_array = order_array.amoeba_dup
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Orders mass assignment.', {
      nickname: 'massAssignmentOrder'
    }
    patch ':id' do
      if params[:orders]
        order_array = current_customer.order_arrays.find(params[:id])
        orders = Hash[order_array.orders.load.map{ |order| [order.id, order] }]
        params[:orders].each{ |id, order|
          id = id.to_i
          order[:product_ids] ||= []
          if orders.key?(id)
            orders[id].product_ids = order[:product_ids].map{ |product_id| Integer(product_id) } & current_customer.product_ids
          end
        }
        order_array.save!
      end
      return
    end
  end
end
