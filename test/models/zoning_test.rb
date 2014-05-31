require 'test_helper'

class ZoningTest < ActiveSupport::TestCase
  test "should not save" do
    o = Zoning.new
    assert_not o.save, "Saved without required fields"
  end
end
