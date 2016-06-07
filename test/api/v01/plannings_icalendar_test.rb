require 'test_helper'

class V01::PlanningsIcalendarTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  require Rails.root.join("test/lib/devices/api_base")
  include ApiBase

  setup do
    @planning = plannings :planning_one
  end

  focus
  test 'Export Planning' do
    get api("/plannings_icalendar/#{@planning.id}")
    assert last_response.ok?
  end
end
