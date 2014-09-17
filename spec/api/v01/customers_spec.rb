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
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['name']).to eq @customer.name
    end
  end

  describe :update do
    it 'Update a customer' do
      @customer.tomtom_user, = 'new name'
      put api(), @customer.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a the customer' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['tomtom_user']).to eq @customer.tomtom_user
    end
  end

  describe :stop_job_matrix do
    it 'Stop job matrix' do
      expect{
        delete api('job_matrix')
        expect(response.status).to eq(200)
      }.to change{Delayed::Backend::ActiveRecord::Job.count}.by(-1)
    end
  end

  describe :stop_job_optimizer do
    it 'Stop job optimizer' do
      expect{
        delete api('job_optimizer')
        expect(response.status).to eq(200)
      }.to change{Delayed::Backend::ActiveRecord::Job.count}.by(-1)
    end
  end

  describe :stop_job_geocoding do
    it 'Stop job geocoding' do
      expect{
        delete api('job_geocoding')
        expect(response.status).to eq(200)
      }.to change{Delayed::Backend::ActiveRecord::Job.count}.by(-1)
    end
  end
end
