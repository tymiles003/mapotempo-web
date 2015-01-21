require 'rails_helper'

describe V01::Customers do
  fixtures :all

  before(:each) do
    @customer = customers(:customer_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/customers#{part}.json?api_key=testkey1"
  end

  describe :get do
    it 'Return a customer' do
      get api(@customer.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @customer.name
    end
  end

  describe :update do
    it 'Update a customer' do
      @customer.tomtom_user, = 'new name'
      put api(@customer.id), @customer.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a the customer' do
      get api(@customer.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['tomtom_user']).to eq @customer.tomtom_user
    end
  end

  describe :get_job do
    it 'Get job' do
      get api("#{@customer.id}/job/#{@customer.job_optimizer_id}")
      expect(response.status).to eq(200)
    end
  end

  describe :delete_job do
    it 'Delete job' do
      expect{
        delete api("#{@customer.id}/job/#{@customer.job_geocoding_id}")
        expect(response.status).to eq(200)
      }.to change{Delayed::Backend::ActiveRecord::Job.count}.by(-1)
    end
  end
end
