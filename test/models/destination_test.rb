require 'test_helper'

class DestinationTest < ActiveSupport::TestCase
  test "should not save" do
    o = Destination.new
    assert_not o.save, "Saved without required fields"
  end
end
