class UserMailer < ApplicationMailer

  def password_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @application_name = user.customer.reseller.application_name || @name
      @email = user.email
      @test = user.customer.test

      @title = t('user_mailer.password.title')
      @confirmation_link = user.customer.reseller.url_protocol + "://" + user.customer.reseller.host + password_user_path(user, token: user.confirmation_token)
      @subscription_duration = user.customer.end_subscription && (user.customer.end_subscription - Date.today).to_i > 1 ? (user.customer.end_subscription - Date.today).to_i : nil
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host

      @logo_link = user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      mail to: @email, from: @application_name , subject: t('user_mailer.password.subject', name: @name) do |format|
        format.html { render 'user_mailer/password', locals: { user: user } }
      end
    end
  end

  def connection_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @application_name = user.customer.reseller.application_name || @name
      @email = user.email

      @title = t('user_mailer.connection.title')
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host

      @logo_link = user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      mail to: @email, from: @application_name, subject: t('user_mailer.connection.subject', name: @name) do |format|
        format.html { render 'user_mailer/connection', locals: { user: user } }
      end
    end
  end

  def self.mail_automation(users)

    users.each do |user|
      date = user.created_at.midnight

      case DateTime.now.in_time_zone.midnight
        when date + 2.days # here is a debugging phase !remove me
          d 'Mail3'
        when date + 3.days
          d 'Mail4'
        when date + 4.days
          d 'Mail5'
        when date + 9.days
          d 'Mail6'
        when date + 14.days
          d 'Mail7' if user.customer.test
        else
          d 'else'
      end
    end
  end
end
