require 'test_helper'

class UserTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = User.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should destroy' do
    o = users(:user_one)
    o.destroy
  end
end
