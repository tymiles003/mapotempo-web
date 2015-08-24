require 'test_helper'

class ZoningTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = Zoning.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should inside' do
    o = zonings(:zoning_one)
    assert o.inside(destinations(:destination_one))
    assert_not o.inside(destinations(:destination_two))
  end

  test 'should apply' do
    o = zonings(:zoning_one)
    assert_equal(
      {nil => [destinations(:destination_two)], zones(:zone_one) => [destinations(:destination_one)]},
      o.apply([destinations(:destination_one), destinations(:destination_two)]))
  end

  test 'should dup' do
    o = zonings(:zoning_one)
    oo = o.amoeba_dup
    assert oo.zones[0].zoning == oo
  end

  test 'should flag_out_of_date' do
    o = zonings(:zoning_one)
    assert_not o.plannings[0].zoning_out_of_date
    o.flag_out_of_date
    assert o.plannings[0].zoning_out_of_date
  end

  test 'should generate automatic clustering' do
    o = zonings(:zoning_one)
    o.automatic_clustering(plannings(:planning_one), 2)
  end

  test 'should generate from planning' do
    o = zonings(:zoning_one)
    o.from_planning(plannings(:planning_one))
  end

  test 'should generate isochrone' do
    o = zonings(:zoning_one)
    o.isochrone(5)
  end
end
