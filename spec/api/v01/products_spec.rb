require 'rails_helper'

describe V01::Products do
  fixtures :all

  before(:each) do
    @product = products(:product_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/products#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s products' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @product.customer.products.size
    end
  end

  describe :get do
    it 'Return a product' do
      get api(@product.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @product.name
    end
  end

  describe :create do
    it 'Create a product' do
      expect{
        @product.name = 'new name'
        @product.code = 'new code'
        post api(), @product.attributes
        expect(response.status).to eq(201)
      }.to change{Product.count}.by(1)
    end
  end

  describe :update do
    it 'Update a product' do
      @product.name = 'new name'
      put api(@product.id), @product.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a product' do
      get api(@product.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @product.name
    end
  end

  describe :destroy do
    it 'Destroy a product' do
      expect{
        delete api(@product.id)
        expect(response.status).to eq(200)
      }.to change{Product.count}.by(-1)
    end
  end
end
