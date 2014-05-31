require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save" do
    o = User.new
    assert_not o.save, "Saved without required fields"
  end
end
