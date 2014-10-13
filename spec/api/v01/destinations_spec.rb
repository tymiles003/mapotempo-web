require 'rails_helper'

describe V01::Destinations do
  fixtures :all

  before(:each) do
    @destination = destinations(:destination_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/destinations#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s destinations' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @destination.customer.destinations.size
    end
  end

  describe :get do
    it 'Return a destination' do
      get api(@destination.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @destination.name
    end
  end

  describe :create do
    it 'Create a destination' do
      expect{
        @destination.name = 'new dest'
        post api(), @destination.attributes
        expect(response.status).to eq(201)
      }.to change{Destination.count}.by(1)
    end
  end

  describe :destroy do
    it 'Destroy a destination' do
      expect{
        delete api(@destination.id)
        expect(response.status).to eq(200)
      }.to change{Destination.count}.by(-1)
    end
  end

  describe :geocode do
    it 'Geocode' do
      patch api('geocode'), format: :json, destination: { city: @destination.city, name: @destination.name, postalcode: @destination.postalcode, street: @destination.street }
      expect(response.status).to eq(200)
    end
  end

  describe :geocode_complete do
    it 'Geocode complete' do
      patch api('geocode_complete'), format: :json, id: @destination.id, destination: { city: 'Montpellier', street: 'Rue de la Chaînerais' }
      expect(response.status).to eq(200)
    end
  end
end
