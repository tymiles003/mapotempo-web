require 'test_helper'

class StopTest < ActiveSupport::TestCase
  test "should not save" do
    o = Stop.new
    assert_not o.save, "Saved without required fields"
  end
end
