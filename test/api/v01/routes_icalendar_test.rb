require 'test_helper'

class V01::RoutesIcalendarTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  require Rails.root.join("test/lib/devices/api_base")
  include ApiBase

  setup do
    @route = routes :route_one_one
  end

  focus
  test 'Export Route' do
    get api("/plannings/#{@route.planning_id}/routes_icalendar/#{@route.id}")
    assert last_response.ok?
  end
end
