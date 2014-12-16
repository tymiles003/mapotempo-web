class V01::OrderArrays < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_array_params
      p = ActionController::Parameters.new(params)
      p = p[:order_array] if p.has_key?(:order_array)
      p.permit(:name, :base_date, :length)
    end
  end

  resource :order_arrays do
    desc "Return customer's order_arrays."
    get do
      present current_customer.order_arrays.load, with: V01::Entities::OrderArray
    end

    desc "Return a order_array."
    get ':id' do
      present current_customer.order_arrays.find(params[:id]), with: V01::Entities::OrderArray
    end

    desc "Create a order_array.", {
      params: V01::Entities::OrderArray.documentation.except(:id)
    }
    post  do
      order_array = current_customer.order_arrays.build(order_array_params)
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc "Update a order_array.", {
      params: V01::Entities::OrderArray.documentation.except(:id)
    }
    put ':id' do
      order_array = current_customer.order_arrays.find(params[:id])
      order_array.update(order_array_params)
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc "Destroy a order_array."
    delete ':id' do
      current_customer.order_arrays.find(params[:id]).destroy
    end

    desc "Clone the order_array."
    patch ':id/duplicate' do
      order_array = current_customer.order_arrays.find(params[:id])
      order_array = order_array.amoeba_dup
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc "Orders mass assignment."
    patch ':id' do
      if params[:orders]
        order_array = current_customer.order_arrays.find(params[:id])
        orders = Hash[order_array.orders.load.map{ |order| [order.id, order] }]
        params[:orders].each{ |id, order|
          id = id.to_i
          order[:product_ids] ||= []
          if orders.has_key?(id)
            orders[id].product_ids = order[:product_ids].map{ |product_id| Integer(product_id) } & current_customer.product_ids
          end
        }
        order_array.save!
      end
      return
    end
  end
end
