require 'test_helper'

class V01::PlanningsGetTest < ActiveSupport::TestCase

  include Rack::Test::Methods

  def app
    Rails.application
  end

  def api path, params = {}
    Addressable::Template.new("/api/0.1/#{path}{?query*}").expand(query: params).to_s
  end

  setup do
    @planning = plannings :planning_one
    @user = @planning.customer.users.take
  end

  test 'Export Planning' do
    ["json", "xml", "ics"].each do |format|
      get api("/plannings/#{@planning.id}.#{format}", { api_key: @user.api_key })
      assert last_response.ok?, last_response.body
    end
  end

  test 'Export Plannings as iCalendar' do
    get api("/plannings.ics", { api_key: @user.api_key })
    assert last_response.ok?, last_response.body
  end

  test 'Export Planning as iCalendar with E-Mail' do
    get api("/plannings/#{@planning.id}.ics", { api_key: @user.api_key, email: 1 })
    assert_equal 204, last_response.status
  end
end
