require 'rails_helper'

describe V01::Zonings do
  fixtures :all

  before(:each) do
    @zoning = zonings(:zoning_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/zonings#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s zonings' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @zoning.customer.zonings.size
    end
  end

  describe :get do
    it 'Return a zoning' do
      get api(@zoning.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @zoning.name
    end
  end

  describe :create do
    it 'Create a zoning' do
      expect{
        @zoning.name = 'new name'
        post api(), @zoning.attributes
        expect(response.status).to eq(201)
      }.to change{Zoning.count}.by(1)
    end
  end

  describe :update do
    it 'Update a zoning' do
      @zoning.name = 'new name'
      put api(@zoning.id), @zoning.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a zoning' do
      get api(@zoning.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @zoning.name
    end
  end

  describe :destroy do
    it 'Destroy a zoning' do
      expect{
        delete api(@zoning.id)
        expect(response.status).to eq(200)
      }.to change{Zoning.count}.by(-1)
    end
  end
end
