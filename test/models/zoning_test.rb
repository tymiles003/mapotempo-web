require 'test_helper'

class ZoningTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Zoning.new
    assert_not o.save, "Saved without required fields"
  end
end
