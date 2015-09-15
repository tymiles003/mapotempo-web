require 'test_helper'

class ZoneTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = Zone.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should touch planning changed' do
    o = zones(:zone_one)
    assert_not o.zoning.plannings[0].zoning_out_of_date
    o.polygon = '{"plop": "plop"}'
    o.save!
    assert o.zoning.plannings[0].zoning_out_of_date
  end

  test 'should touch planning collection changed' do
    o = zones(:zone_one)
    assert_not o.zoning.plannings[0].zoning_out_of_date
    assert o.vehicle
    o.vehicle = nil
    o.save!
    o.zoning.save!
    o.reload
    assert o.zoning.plannings[0].zoning_out_of_date
  end

  test 'calculate distance between point and simple polygon' do
    o = zones(:zone_one)
    assert_equal 0.0014045718474348943, o.inside_distance(49.538, -0.976)
  end

  test 'calculate distance between point and isochrone' do
    o = zones(:zone_three)
    assert_equal 0.00490917508345431, o.inside_distance(44.8414, -0.581)
  end
end
