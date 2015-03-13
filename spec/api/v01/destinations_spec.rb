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

  describe :get_ref do
    it 'Return a destination by ref' do
      get api("ref:#{@destination.ref}")
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['ref']).to eq @destination.ref
    end
  end

  describe :create do
    subject { -> {
        @destination.name = 'new dest'
        post api(), @destination.attributes.update({tag_ids: [tags(:tag_one).id]})
        expect(response.status).to eq(201)
      }
    }

    it "change destination count" do
      should change{Destination.count}.by(1)
    end

    it "change stop count" do
      should change{Stop.count}.by(1)
    end
  end

  describe :create_bulk_from_csv do
    subject { -> {
        put api(), replace: false, file: fixture_file_upload('test/fixtures/files/import_one.csv', 'text/csv')
        expect(response.status).to eq(204)
      }
    }

    it "change destination count" do
      should change{Destination.count}.by(1)
    end
  end

  describe :create_bulk_from_json do
    subject { -> {
        put api(), {destinations: [{
          name: "Nouveau client",
          street: nil,
          postalcode: nil,
          city: "Tule",
          lat: 43.5710885456786,
          lng: 3.89636993408203,
          quantity: nil,
          open: nil,
          close: nil,
          detail: nil,
          comment: nil,
          ref: nil,
          take_over: nil,
          tag_ids: [],
          geocoding_accuracy: nil,
          foo: 'bar'
        }]}
        expect(response.status).to eq(204)
      }
    }

    it "change destination count" do
      should change{Destination.count}.by(1)
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
