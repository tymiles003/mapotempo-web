require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'should not save' do
    user = User.new
    assert_not user.save, 'Saved without required fields'
  end

  test 'should destroy' do
    user = users(:user_one)
    user.destroy
  end
end
