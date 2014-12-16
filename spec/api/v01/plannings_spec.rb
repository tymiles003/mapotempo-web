require 'rails_helper'

describe V01::Plannings do
  fixtures :all

  before(:each) do
    @planning = plannings(:planning_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s plannings' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @planning.customer.plannings.size
    end
  end

  describe :get do
    it 'Return a planning' do
      get api(@planning.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @planning.name
    end
  end

  describe :create do
    it 'Create a planning' do
      expect{
        @planning.name = 'new name'
        post api(), @planning.attributes
        expect(response.status).to eq(201)
      }.to change{Planning.count}.by(1)
    end
  end

  describe :update do
    it 'Update a planning' do
      @planning.name = 'new name'
      put api(@planning.id), @planning.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a planning' do
      get api(@planning.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @planning.name
    end
  end

  describe :destroy do
    it 'Destroy a planning' do
      expect{
        delete api(@planning.id)
        expect(response.status).to eq(200)
      }.to change{Planning.count}.by(-1)
    end
  end

  describe :refresh do
    it 'Force recompute the planning after parameter update' do
      get api("#{@planning.id}/refresh")
      expect(response.status).to eq(200)
    end
  end

#  describe :switch do
#    it 'Switch two vehicles' do
#      patch api("#{@planning.id}/switch")
#      expect(response.status).to eq(200)
#    end
#  end

#  describe :automatic_insert do
#    it 'Suggest a place for an unaffected destination' do
#      patch api("#{@planning.id}/automatic_insert")
#      expect(response.status).to eq(200)
#    end
#  end

#  describe :update_stop do
#    it 'Set stop status' do
#      patch api("#{@planning.id}/update_stop")
#      expect(response.status).to eq(200)
#    end
#  end

#  describe :optimize_route do
#    it 'Starts asynchronous route optimization' do
#      get api("#{@planning.id}/optimize_route")
#      expect(response.status).to eq(200)
#    end
#  end

  describe :active do
    it 'Change stops activation' do
      patch api("#{@planning.id}/routes/#{@planning.routes[1].id}/active/all")
      expect(response.status).to eq(200)
      patch api("#{@planning.id}/routes/#{@planning.routes[1].id}/active/reverse")
      expect(response.status).to eq(200)
    end
  end

  describe :duplicate do
    it 'Clone the planning' do
      expect{
        patch api("#{@planning.id}/duplicate")
        expect(response.status).to eq(200)
      }.to change{Planning.count}.by(1)
    end
  end

  describe :orders do
    it 'Apply orders' do
      expect(@planning.routes[1].stops[0].active).to eq(true)
      expect(@planning.routes[1].stops[1].active).to eq(true)
      @order_array = order_arrays(:order_array_one)
      patch api("#{@planning.id}/orders/#{@order_array.id}/0")

      @planning.reload
      expect(@planning.routes[1].stops[0].active).to eq(true)
      expect(@planning.routes[1].stops[1].active).to eq(false)
    end
  end
end
