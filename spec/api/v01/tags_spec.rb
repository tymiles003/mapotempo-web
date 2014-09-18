require 'rails_helper'

describe V01::Tags do
  fixtures :all

  before(:each) do
    @tag = tags(:tag_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/tags#{part}.json?api_key=testkey1"
  end

  describe :list do
    it 'Return customer''s tags' do
      get api()
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).size).to eq @tag.customer.tags.size
    end
  end

  describe :get do
    it 'Return a tag' do
      get api(@tag.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['label']).to eq @tag.label
    end
  end

  describe :create do
    it 'Create a tag' do
      expect{
        @tag.label = 'new label'
        post api(), @tag.attributes
        expect(response.status).to eq(201)
      }.to change{Tag.count}.by(1)
    end
  end

  describe :update do
    it 'Update a tag' do
      @tag.label = 'new label'
      put api(@tag.id), @tag.attributes
      expect(response.status).to eq(200)
    end

    it 'Return a tag' do
      get api(@tag.id)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['label']).to eq @tag.label
    end
  end

  describe :destroy do
    it 'Destroy a tag' do
      expect{
        delete api(@tag.id)
        expect(response.status).to eq(200)
      }.to change{Tag.count}.by(-1)
    end
  end
end
