require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test "should not save" do
    o = Tag.new
    assert_not o.save, "Saved without required fields"
  end
end
