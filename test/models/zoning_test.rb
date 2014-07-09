require 'test_helper'

class ZoningTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Zoning.new
    assert_not o.save, "Saved without required fields"
  end

  test "should inside" do
    o = zonings(:zoning_one)
    assert o.inside(destinations(:destination_one))
    assert_not o.inside(destinations(:destination_two))
  end

  test "should apply" do
    o = zonings(:zoning_one)
    assert_equal(
      {nil => [destinations(:destination_two)], zones(:zone_one) => [destinations(:destination_one)]},
      o.apply([destinations(:destination_one), destinations(:destination_two)]))
  end

  test "should dup" do
    o = zonings(:zoning_one)
    oo = o.amoeba_dup
    assert oo.zones[0].zoning == oo
  end
end
