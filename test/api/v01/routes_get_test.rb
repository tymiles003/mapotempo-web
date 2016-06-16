require 'test_helper'

class V01::RoutesGetTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  include ApiBase

  def app
    Rails.application
  end

  def api path, params = {}
    Addressable::Template.new("/api/0.1/#{path}{?query*}").expand(query: params).to_s
  end

  setup do
    @route = routes :route_one_one
    @user = @route.planning.customer.users.take
  end

  test 'Export Route' do
    ["json", "xml", "ics"].each do |format|
      get api("/plannings/#{@route.planning_id}/routes/#{@route.id}.#{format}", { api_key: @user.api_key })
      assert last_response.ok?, last_response.body
    end
  end

  test 'Export Route as iCalendar with E-Mail' do
    get api("/plannings/#{@route.planning_id}/routes/#{@route.id}.ics", { api_key: @user.api_key, email: 1 })
    assert_equal 204, last_response.status
  end
end
