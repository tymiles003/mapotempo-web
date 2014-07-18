require 'test_helper'

class ZoneTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Zone.new
    assert_not o.save, "Saved without required fields"
  end

  test "should touch planning changed" do
    o = zones(:zone_one)
    assert_not o.zoning.plannings[0].zoning_out_of_date
    o.polygon = "plop"
    o.save!
    assert o.zoning.plannings[0].zoning_out_of_date
  end

  test "should touch planning collection changed" do
    o = zones(:zone_one)
    assert_not o.zoning.plannings[0].zoning_out_of_date
    assert_not_equal 0, o.vehicles.size
    o.vehicles.clear
    o.save!
    assert o.zoning.plannings[0].zoning_out_of_date
  end
end
