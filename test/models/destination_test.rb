require 'test_helper'

class DestinationTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = Destination.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    assert_difference('Stop.count', 1) do
      assert_difference('Destination.count') do
        assert_difference('Order.count', 7 * 2) do
          customer = customers(:customer_one)
          d = customer.destinations.build(name: 'plop', city: 'Bordeaux')
          d.visits.build(tags: [tags(:tag_one)])
          assert d.save!
          assert customer.save!
          d.reload
          assert !d.lat.nil?, 'Latitude not built'
        end
      end
    end
  end

  test 'should geocode' do
    o = destinations(:destination_one)
    lat, lng = o.lat, o.lng
    o.geocode
    assert o.lat
    assert_not_equal lat, o.lat
    assert o.lng
    assert_not_equal lng, o.lng
  end

  test 'should update_geocode' do
    o = destinations(:destination_one)
    o.city = 'Toulouse'
    o.lat = o.lng = nil
    lat, lng = o.lat, o.lng
    o.save!
    assert o.lat
    assert_not_equal lat, o.lat
    assert o.lng
    assert_not_equal lng, o.lng
  end

  test 'should distance' do
    o = destinations(:destination_one)
    assert_equal 47.72248931834969, o.distance(destinations(:destination_two))
  end

  test 'should destroy and reindex stops' do
    r = routes(:route_one_one)
    d = destinations(:destination_one)

    r.touch
    r.save!

    assert d.visits
    d.destroy

    r.reload
    r.touch
    r.save!
  end
end
