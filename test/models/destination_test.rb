require 'test_helper'

class DestinationTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Destination.new
    assert_not o.save, "Saved without required fields"
  end

  test "should save" do
    assert_difference('Stop.count', 1) do
      assert_difference('Destination.count') do
        assert_difference('Order.count', 7 * 2) do
          customer = customers(:customer_one)
          o = customer.destinations.build(name: "plop", city: "Bordeaux", lat: 1, lng: 1, tags: [tags(:tag_one)])
          assert o.save
          assert customer.save
        end
      end
    end
  end

  test "should geocode" do
    o = destinations(:destination_one)
    lat, lng = o.lat, o.lng
    o.geocode
    assert o.lat
    assert_not_equal lat, o.lat
    assert o.lng
    assert_not_equal lng, o.lng
  end

  test "should update_geocode" do
    o = destinations(:destination_one)
    o.city = "Toulouse"
    lat, lng = o.lat, o.lng
    o.save!
    assert o.lat
    assert_not_equal lat, o.lat
    assert o.lng
    assert_not_equal lng, o.lng
  end

  test "should distance" do
    o = destinations(:destination_one)
    assert_equal 47.72248931834969, o.distance(destinations(:destination_two))
  end

  test "should update add tag" do
    o = destinations(:destination_one)
    assert_difference('Stop.count') do
      o.tags << tags(:tag_two)
      o.save!
      o.customer.save!
    end
  end

  test "should update remove tag" do
    o = destinations(:destination_one)
    assert_difference('Stop.count', -1) do
      o.tags = []
      o.save!
      o.customer.save!
    end
  end

  test "should update tag" do
    o = destinations(:destination_one)
    p = plannings(:planning_one)
    p.tags = [tags(:tag_one), tags(:tag_two)]

    routes(:route_one).stops.clear
    o.tags = []

    assert_difference('Stop.count', 0) do
      o.tags = [tags(:tag_one)]
      o.save!
      o.customer.save!
    end

    assert_difference('Stop.count', 2) do
      o.tags = [tags(:tag_one), tags(:tag_two)]
      o.save!
      o.customer.save!
    end
  end

  test "should destroy and reindex stops" do
    r = routes(:route_one)
    o = destinations(:destination_one)

    r.touch
    r.save!

    assert o.stops
    o.destroy

    r.reload
    r.touch
    r.save!
  end
end
