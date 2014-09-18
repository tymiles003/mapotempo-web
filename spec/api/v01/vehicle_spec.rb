require 'rails_helper'

describe V01::Vehicles do
  fixtures :all

  before(:each) do
    @vehicle = vehicles(:vehicle_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/vehicles#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s vehicles' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @vehicle.customer.vehicles.size
    end
  end

  describe :get do
    it 'Return a vehicle' do
      get api(@vehicle.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @vehicle.name
    end
  end

  describe :update do
    it 'Update a vehicle' do
      @vehicle.name = 'new name'
      put api(@vehicle.id), @vehicle.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a vehicle' do
      get api(@vehicle.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @vehicle.name
    end
  end
end
