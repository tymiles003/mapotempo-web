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
    desc 'Fetch customer''s products.', {
      nickname: 'getProducts'
    }
    get do
      present current_customer.products.load, with: V01::Entities::Product
    end

    desc 'Fetch product.', {
      nickname: 'getProduct'
    }
    get ':id' do
      present current_customer.products.find(params[:id]), with: V01::Entities::Product
    end

    desc 'Create product.', {
      nickname: 'createProduct',
      params: V01::Entities::Product.documentation.except(:id)
    }
    post  do
      product = current_customer.products.build(product_params)
      product.save!
      present product, with: V01::Entities::Product
    end

    desc 'Update product.', {
      nickname: 'updateProduct',
      params: V01::Entities::Product.documentation.except(:id)
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
    delete ':id' do
      current_customer.products.find(params[:id]).destroy
    end
  end
end
