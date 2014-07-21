require 'test_helper'

class PlanningTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    def Trace.compute(from_lat, from_lng, to_lat, to_lng)
      [1, 1, "trace"]
    end
  end

  test "should not save" do
    o = Planning.new
    assert_not o.save, "Saved without required fields"
  end

  test "should save" do
    o = customers(:customer_one).plannings.build(name: "plop", zoning: zonings(:zoning_one))
    o.default_routes
    o.save!
  end

  test "should dup" do
    o = plannings(:planning_one)
    oo = o.amoeba_dup

    assert_equal oo, oo.routes[0].planning
  end

  test "should set_destinations" do
    o = plannings(:planning_one)

    o.set_destinations([[destinations(:destination_one)]])
    assert o.routes[1].stops.collect(&:destination).include?(destinations(:destination_one))
  end

  test "should not set_destinations" do
    o = plannings(:planning_one)

    assert_raises(RuntimeError) {
      o.set_destinations([[destinations(:destination_one)]] * (o.routes.size+1))
    }
  end

  test "should vehicle_add" do
    o = plannings(:planning_one)
    assert_difference('Stop.count', 2) do
      assert_difference('Route.count', 1) do
        o.vehicle_add(vehicles(:vehicle_two))
        o.save!
      end
    end
  end

  test "should vehicle_remove" do
    o = plannings(:planning_one)
    assert_difference('Stop.count', -4) do
      assert_difference('Route.count', -1) do
        o.vehicle_remove(vehicles(:vehicle_one))
        o.save!
      end
    end
  end

  test "should destination_add" do
    o = plannings(:planning_one)
    assert_difference('Stop.count') do
      o.destination_add(destinations(:destination_two))
      o.save!
    end
  end

  test "should destination_remove" do
    o = plannings(:planning_one)
    assert_difference('Stop.count', -1) do
      o.destination_remove(destinations(:destination_one))
      o.save!
    end
  end

  test "should compute" do
    o = plannings(:planning_one)
    o.zoning_out_of_date = true
    o.compute
    o.routes.select{ |r| r.vehicle }.each{ |r|
      assert_not r.out_of_date
    }
    assert_not o.zoning_out_of_date
  end

  test "should out_of_date" do
    o = plannings(:planning_one)
    assert_not o.out_of_date

    o.routes[1].out_of_date = true
    assert o.out_of_date
  end
end
