require 'test_helper'

class ZoneTest < ActiveSupport::TestCase
  test "should not save" do
    o = Zone.new
    assert_not o.save, "Saved without required fields"
  end
end
