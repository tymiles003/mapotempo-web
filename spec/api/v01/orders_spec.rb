require 'rails_helper'

describe V01::Orders do
  fixtures :all

  before(:each) do
    @order = orders(:order_one)
  end

  def api(order_array_id, part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/order_arrays/#{order_array_id}/orders#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return order_array''s orders' do
      get api(@order.order_array.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @order.order_array.orders.size
    end
  end

  describe :get do
    it 'Return a order' do
      get api(@order.order_array.id, @order.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['product_ids']).to eq @order.products.collect(&:id)
    end
  end

  describe :update do
    it 'Update a order' do
      @order.product_ids = [products(:product_two).id]
      put api(@order.order_array.id, @order.id), @order.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a order' do
      get api(@order.order_array.id, @order.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['product_ids']).to eq @order.products.collect(&:id)
    end
  end

  describe :mass_assignment do
    it 'Do orders mass assignment' do
      @order.product_ids = [products(:product_two).id]
      put api(@order.order_array.id), {@order.id => @order.attributes}
      expect(response.status).to eq(200)

      @order.reload
      expect(@order.product_ids).to eq([products(:product_two).id])
    end
  end
end
