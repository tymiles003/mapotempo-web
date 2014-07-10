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
end
