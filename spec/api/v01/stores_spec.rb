require 'rails_helper'

describe V01::Stores do
  fixtures :all

  before(:each) do
    @store = stores(:store_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/stores#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s stores' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @store.customer.stores.size
    end
  end

  describe :get do
    it 'Return a store' do
      get api(@store.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @store.name
    end
  end

  describe :create do
    it 'Create a store' do
      expect{
        @store.name = 'new dest'
        post api(), @store.attributes
        expect(response.status).to eq(201)
      }.to change{Store.count}.by(1)
    end
  end

  describe :destroy do
    it 'Destroy a store' do
      expect{
        delete api(@store.id)
        expect(response.status).to eq(200)
      }.to change{Store.count}.by(-1)
    end
  end

  describe :geocode do
    it 'Geocode' do
      patch api('geocode'), format: :json, store: { city: @store.city, name: @store.name, postalcode: @store.postalcode, street: @store.street }
      expect(response.status).to eq(200)
    end
  end

  describe :geocode_complete do
    it 'Geocode complete' do
      patch api('geocode_complete'), format: :json, id: @store.id, store: { city: 'Montpellier', street: 'Rue de la Chaînerais' }
      expect(response.status).to eq(200)
    end
  end
end
