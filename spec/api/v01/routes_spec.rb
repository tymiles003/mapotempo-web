require 'rails_helper'

describe V01::Routes do
  fixtures :all

  before(:each) do
    @route = routes(:route_one)
  end

  def api(destination_id, part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings/#{destination_id}/routes#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s routes' do
      get api(@route.planning.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @route.planning.routes.size
    end
  end

  describe :get do
    it 'Return a route' do
      get api(@route.planning.id, @route.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['stops'].size).to eq @route.stops.size
    end
  end

  describe :update do
    it 'Update a route' do
      @route.locked = true
      put api(@route.planning.id, @route.id), @route.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a route' do
      get api(@route.planning.id, @route.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['locked']).to eq @route.locked
    end
  end

  describe :move do
    it 'Move destination position in routes' do
      patch api(@route.planning.id, "#{@route.id}/destinations/#{@route.planning.routes[0].stops[0].destination.id}/move/1"), @route.attributes
      expect(response.status).to eq(200)
    end
  end
end
