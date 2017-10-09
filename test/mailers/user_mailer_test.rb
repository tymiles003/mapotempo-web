require 'test_helper'

class UserMailerTest < ActionMailer::TestCase

  test 'should send password email' do
    user_one = users(:user_one)
    reseller_name = user_one.customer.reseller.name
    email = UserMailer.password_message(user_one, I18n.locale)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['u1@plop.com'], email.to
    assert_equal I18n.t('user_mailer.password.subject', name: reseller_name), email.subject
  end

  test 'should send password email with uploaded image' do
    user_one = users(:user_one)
    reseller = user_one.customer.reseller
    reseller_name = user_one.customer.reseller.name
    file = Rack::Test::UploadedFile.new(Rails.root.join('test', 'fixtures', 'logo', 'logo_mapotempo.png'), 'image/png')
    reseller.logo_large = file
    reseller.save!

    email = UserMailer.password_message(user_one, I18n.locale)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['u1@plop.com'], email.to
    assert_equal I18n.t('user_mailer.password.subject', name: reseller_name), email.subject
  end

  test 'should send connection email' do
    user_one = users(:user_one)
    reseller_name = user_one.customer.reseller.name
    email = UserMailer.connection_message(user_one, I18n.locale)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['u1@plop.com'], email.to
    assert_equal I18n.t('user_mailer.connection.subject', name: reseller_name), email.subject
  end
end
