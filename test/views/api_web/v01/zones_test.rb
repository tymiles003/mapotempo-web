require 'test_helper'

class ApiWeb::V01::ZonesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @zoning = zonings(:zoning_one)
  end

  test 'Api-web: should return json for zones' do
    [:get, :post].each do |method|
      send method, "/api-web/0.1/zonings/#{@zoning.id}/zones.json?api_key=testkey1"
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal @zoning.zones.size, json['zoning'].size
      assert_equal customers(:customer_one).stores.size, json['stores'].size
    end
  end

  test 'Api-web: should return json for some zones' do
    [:get, :post].each do |method|
      send method, "/api-web/0.1/zonings/#{@zoning.id}/zones.json?api_key=testkey1", {ids: zones(:zone_one).id.to_s + ',' + zones(:zone_two).id.to_s}
      assert last_response.ok?, last_response.body
      json = JSON.parse(last_response.body)
      assert_equal 2, json['zoning'].size
    end
  end

  # TODO: visit_ids in controller
  # test 'Api-web: should return json for zones with dest & stores' do
  #   [:get, :post].each do |method|
  #     send method, "/api-web/0.1/zonings/#{@zoning.id}/zones.json?api_key=testkey1", {visit_ids: visits(:visit_one).id.to_s, store_ids: stores(:store_one).id.to_s + ',' + stores(:store_one_bis).id.to_s}
  #     assert last_response.ok?, last_response.body
  #     json = JSON.parse(last_response.body)
  #     assert_equal 2, json['zoning'].size
  #   end
  # end
end
