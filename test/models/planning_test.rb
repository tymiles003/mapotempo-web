require 'test_helper'

class PlanningTest < ActiveSupport::TestCase
  test "should not save" do
    o = Planning.new
    assert_not o.save, "Saved without required fields"
  end
end
