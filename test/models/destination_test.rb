require 'test_helper'

class DestinationTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Destination.new
    assert_not o.save, "Saved without required fields"
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

  test "should reverse_geocode" do
    o = destinations(:destination_one)
    city = o.city
    o.reverse_geocode
    assert o.city
    assert_not_equal city, o.city
  end

  test "should distance" do
    o = destinations(:destination_one)
    assert_equal 47.72248931834969, o.distance(destinations(:destination_two))
  end

  test "should update add tag" do
    o = destinations(:destination_one)
    assert_difference('Stop.count') do
      o.tags << tags(:tag_two)
    end
  end

  test "should update remove tag" do
    o = destinations(:destination_one)
    assert_difference('Stop.count', -1) do
      o.tags = []
    end
  end

  test "should update tag" do
    o = destinations(:destination_one)
    p = plannings(:planning_one)
    p.tags = [tags(:tag_one), tags(:tag_two)]

    routes(:route_one).default_store
    o.tags = []

    assert_difference('Stop.count', 0) do
      o.tags = [tags(:tag_one)]
    end

    assert_difference('Stop.count', 1) do
      o.tags = [tags(:tag_one), tags(:tag_two)]
    end
  end
end
