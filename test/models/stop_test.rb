require 'test_helper'

class StopTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Stop.new
    assert_not o.save, "Saved without required fields"
  end
end
