require 'test_helper'

class ZoningTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

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
      {nil => [visits(:visit_two)], zones(:zone_one) => [visits(:visit_one)]},
      o.apply([visits(:visit_one), visits(:visit_two)]))
  end

  test 'should dup' do
    o = zonings(:zoning_one)
    oo = o.duplicate
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
    assert 2, o.zones.size
  end

  test 'should generate automatic clustering with disabled vehicles' do
    p = plannings(:planning_one)
    p.vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_three)
    o = zonings(:zoning_one)
    o.automatic_clustering(p, 2)
    assert 1, o.zones.size
  end

  test 'should generate from planning' do
    o = zonings(:zoning_one)
    o.from_planning(plannings(:planning_one))
  end

  test 'should generate isochrones' do
    begin
      store_one = stores(:store_one)
      stub_isochrone = stub_request(:get, 'localhost:1723/0.1/isochrone').with(:query => hash_including({})).
        to_return(File.new(File.expand_path('../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
      o = zonings(:zoning_one)
      o.isochrones(5, o.customer.vehicle_usage_sets[0])
    ensure
      remove_request_stub(stub_isochrone) if stub_isochrone
    end
  end
end
