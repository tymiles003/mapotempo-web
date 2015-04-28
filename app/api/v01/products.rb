class V01::Products < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      p = ActionController::Parameters.new(params)
      p = p[:product] if p.key?(:product)
      p.permit(:name, :code)
    end
  end

  resource :products do
    desc 'Fetch customer\'s products.', {
      nickname: 'getProducts',
      is_array: true,
      entity: V01::Entities::Product
    }
    get do
      present current_customer.products.load, with: V01::Entities::Product
    end

    desc 'Fetch product.', {
      nickname: 'getProduct',
      entity: V01::Entities::Product
    }
    params {
      requires :id, type: Integer
    }
    get ':id' do
      present current_customer.products.find(params[:id]), with: V01::Entities::Product
    end

    desc 'Create product.', {
      nickname: 'createProduct',
      params: V01::Entities::Product.documentation.except(:id).merge({
        code: { required: true },
        name: { required: true }
      }),
      entity: V01::Entities::Product
    }
    post do
      product = current_customer.products.build(product_params)
      product.save!
      present product, with: V01::Entities::Product
    end

    desc 'Update product.', {
      nickname: 'updateProduct',
      params: V01::Entities::Product.documentation.except(:id),
      entity: V01::Entities::Product
    }
    params {
      requires :id, type: Integer
    }
    put ':id' do
      product = current_customer.products.find(params[:id])
      product.update(product_params)
      product.save!
      present product, with: V01::Entities::Product
    end

    desc 'Delete product.', {
      nickname: 'deleteProduct'
    }
    params {
      requires :id, type: Integer
    }
    delete ':id' do
      current_customer.products.find(params[:id]).destroy
    end

    desc 'Delete multiple products.', {
      nickname: 'deleteProducts'
    }
    params {
      requires :ids, type: Array[Integer]
    }
    delete do
      Product.transaction do
        ids = params[:ids].collect(&:to_i)
        current_customer.products.select{ |product| ids.include?(product.id) }.each(&:destroy)
      end
    end
  end
end
