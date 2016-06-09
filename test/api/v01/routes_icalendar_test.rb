require 'test_helper'

class V01::RoutesIcalendarTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  include ApiBase

  def app
    Rails.application
  end

  def api path, params = {}
    Addressable::Template.new("/api/0.1/#{path}{?query*}").expand(query: params.merge(api_key: 'testkey1')).to_s
  end

  setup do
    @route = routes :route_one_one
  end

  test 'Export Route' do
    get api("/plannings/#{@route.planning_id}/routes/#{@route.id}.ics")
    assert last_response.ok?
  end
end
