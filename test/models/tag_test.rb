require 'test_helper'

class TagTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = customers(:customer_one).tags.build
    assert_not o.save, "Saved without required fields"
  end

  test "should not save color" do
    o = customers(:customer_one).tags.build(label: "plop", color: "red")
    assert_not o.save, "Saved with invalid color"
  end

  test "should save" do
    o = customers(:customer_one).tags.build(label: "plop", color: "#ff0000", icon: "diamon")
    assert o.save
  end
end
