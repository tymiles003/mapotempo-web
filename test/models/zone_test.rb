require 'test_helper'

class ZoneTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Zone.new
    assert_not o.save, "Saved without required fields"
  end
end
