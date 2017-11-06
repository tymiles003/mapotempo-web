require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def user_hash(customer, locale)
    { locale: locale, customer: customer, email: 'julien@mapotempo.com', password: 'dummy_password' }
  end

  test 'should not save' do
    user = User.new
    assert_not user.save, 'Saved without required fields'
  end

  test 'should destroy' do
    user = users(:user_one)
    user.destroy
  end

  test 'should create with locale' do
    user = User.create(user_hash(customers(:customer_one), 'fr'))
    assert user.valid?
  end

  test 'shouldn\t be valid on wrong locale' do
    user = User.create(user_hash(customers(:customer_one), 'ee'))
    assert_not user.valid?
  end
end
