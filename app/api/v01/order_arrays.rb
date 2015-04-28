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
    desc 'Fetch customer\'s order_arrays.', {
      nickname: 'getOrderArrays',
      is_array: true,
      entity: V01::Entities::OrderArray
    }
    get do
      present current_customer.order_arrays.load, with: V01::Entities::OrderArray
    end

    desc 'Fetch order_array.', {
      nickname: 'getOrderArray',
      entity: V01::Entities::OrderArray
    }
    params {
      requires :id, type: Integer
    }
    get ':id' do
      present current_customer.order_arrays.find(params[:id]), with: V01::Entities::OrderArray
    end

    desc 'Create order_array.', {
      nickname: 'createOrderArray',
      params: V01::Entities::OrderArray.documentation.except(:id, :orders).merge({
        name: { required: true },
        base_date: { required: true },
        length: { required: true }
      }),
      entity: V01::Entities::OrderArray
    }
    post do
      order_array = current_customer.order_arrays.build(order_array_params)
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Update order_array.', {
      nickname: 'updateOrderArray',
      params: V01::Entities::OrderArray.documentation.except(:id, :orders),
      entity: V01::Entities::OrderArray
    }
    params {
      requires :id, type: Integer
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
    params {
      requires :id, type: Integer
    }
    delete ':id' do
      current_customer.order_arrays.find(params[:id]).destroy
    end

    desc 'Delete multiple order_arrays.', {
      nickname: 'deleteOrderArrays'
    }
    params {
      requires :ids, type: Array[Integer]
    }
    delete do
      OrderArray.transaction do
        ids = params[:ids].collect(&:to_i)
        current_customer.order_arrays.select{ |order_array| ids.include?(order_array.id) }.each(&:destroy)
      end
    end

    desc 'Clone the order_array.', {
      nickname: 'cloneOrderArray',
      entity: V01::Entities::OrderArray
    }
    params {
      requires :id, type: Integer
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
    params {
      requires :id, type: Integer
    }
    patch ':id' do
      if params[:orders]
        order_array = current_customer.order_arrays.find(params[:id])
        orders = Hash[order_array.orders.load.map{ |order| [order.id, order] }]
        products = Hash[current_customer.products.collect{ |product| [product.id, product] }]
        params[:orders].each{ |id, order|
          id = id.to_i
          order[:product_ids] ||= []
          if orders.key?(id)
            # Workaround for multiple values need add values and not affect
            orders[id].products.clear
            orders[id].products += order[:product_ids].map{ |product_id| products[product_id.to_i] }.select{ |i| i }
          end
        }
        order_array.save!
      end
      return
    end
  end
end
