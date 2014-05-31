require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  test "should not save" do
    o = Vehicle.new
    assert_not o.save, "Saved without required fields"
  end
end
