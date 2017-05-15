require 'test_helper'

class ZoningsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @zoning = zonings(:zoning_one)
  end

  test 'should return json for zoning' do
    get "/zonings/#{@zoning.id}/edit.json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    json = JSON.parse(last_response.body)
    assert_equal @zoning.zones.size, json['zoning'].size
  end
end
