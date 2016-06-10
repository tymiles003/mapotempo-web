require 'test_helper'

class V01::PlanningsIcalendarTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  include ApiBase

  def app
    Rails.application
  end

  def api path, params = {}
    Addressable::Template.new("/api/0.1/#{path}{?query*}").expand(query: params.merge(api_key: 'testkey1')).to_s
  end

  setup do
    @planning = plannings :planning_one
  end

  test 'Export Planning' do
    get api("/plannings/#{@planning.id}.ics")
    assert last_response.ok?, last_response.body
  end
end
