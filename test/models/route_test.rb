require 'test_helper'

class RouteTest < ActiveSupport::TestCase
  test "should not save" do
    o = Route.new
    assert_not o.save, "Saved without required fields"
  end
end
