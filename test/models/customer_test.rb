require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  test "should not save" do
    o = Customer.new
    assert_not o.save, "Saved without required fields"
  end
end
