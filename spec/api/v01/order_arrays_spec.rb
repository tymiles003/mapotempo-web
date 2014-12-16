require 'rails_helper'

describe V01::OrderArrays do
  fixtures :all

  before(:each) do
    @order_array = order_arrays(:order_array_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/order_arrays#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s order_arrays' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @order_array.customer.order_arrays.size
    end
  end

  describe :get do
    it 'Return a order_array' do
      get api(@order_array.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @order_array.name
    end
  end

  describe :create do
    it 'Create a order_array' do
      expect{
        post api(), {name: 'new name', length: @order_array.length, base_date: Date.new}
        expect(response.status).to eq(201)
      }.to change{OrderArray.count}.by(1)
    end
  end

  describe :update do
    it 'Update a order_array' do
      put api(@order_array.id), {name: 'new name'}
      expect(response.status).to eq(200)
    end

    it 'Return a order_array' do
      get api(@order_array.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @order_array.name
    end
  end

  describe :destroy do
    it 'Destroy a order_array' do
      expect{
        delete api(@order_array.id)
        expect(response.status).to eq(200)
      }.to change{OrderArray.count}.by(-1)
    end
  end

  describe :duplicate do
    it 'Clone the order_array' do
      expect{
        patch api("#{@order_array.id}/duplicate")
        expect(response.status).to eq(200)
      }.to change{OrderArray.count}.by(1)
    end
  end
end
