require 'test_helper'

class ZoningTest < ActiveSupport::TestCase

  test 'should not save' do
    zoning = Zoning.new
    assert_not zoning.save, 'Saved without required fields'
  end

  test 'should inside' do
    zoning = zonings(:zoning_one)
    assert zoning.inside(destinations(:destination_one))
    assert_not zoning.inside(destinations(:destination_two))
  end

  test 'should apply' do
    zoning = zonings(:zoning_one)
    assert_equal(
      {nil => [visits(:visit_two)], zones(:zone_one) => [visits(:visit_one)]},
      zoning.apply([visits(:visit_one), visits(:visit_two)]))
  end

  test 'should dup' do
    zoning = zonings(:zoning_one)
    oo = zoning.duplicate
    assert oo.zones[0].zoning == oo
  end

  test 'should flag_out_of_date' do
    zoning = zonings(:zoning_one)
    assert_not zoning.plannings[0].zoning_out_of_date
    zoning.flag_out_of_date
    assert zoning.plannings[0].zoning_out_of_date
  end

  test 'should generate automatic clustering' do
    zoning = zonings(:zoning_one)
    zoning.automatic_clustering(plannings(:planning_one), 2)
    assert 2, zoning.zones.size
  end

  test 'should generate automatic clustering with disabled vehicles' do
    planning = plannings(:planning_one)
    planning.vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_three)
    zoning = zonings(:zoning_one)
    zoning.automatic_clustering(planning, 2)
    assert 1, zoning.zones.size
  end

  test 'should generate from planning' do
    zoning = zonings(:zoning_one)
    zoning.from_planning(plannings(:planning_one))
  end

  test 'should generate isochrones' do
    begin
      store_one = stores(:store_one)
      stub_isochrone = stub_request(:post, 'localhost:5000/0.1/isoline.json').with(:query => hash_including({})).
        to_return(File.new(File.expand_path('../../web_mocks/', __FILE__) + '/isochrone/isochrone-1.json').read)
      zoning = zonings(:zoning_one)
      zoning.isochrones(5, zoning.customer.vehicle_usage_sets[0])
    ensure
      remove_request_stub(stub_isochrone) if stub_isochrone
    end
  end

  test 'Automatic Clustering, Include Unaffected' do
    customer = customers :customer_one
    planning = plannings :planning_one
    zoning = customer.zonings.new
    assert planning.routes.detect{|route| !route.vehicle_usage }.stops.exists?
    zoning.automatic_clustering planning, nil, true
    assert_equal customer.vehicles.count, zoning.zones.length
  end

  test 'Automatic Clustering, Reject Unaffected' do
    customer = customers :customer_one
    planning = plannings :planning_one
    zoning = customer.zonings.new
    assert planning.routes.detect{|route| !route.vehicle_usage }.stops.exists?
    zoning.automatic_clustering planning, nil, false
    assert_equal customer.vehicles.count, zoning.zones.length
  end

end
