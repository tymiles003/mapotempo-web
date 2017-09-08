class UserMailer < ApplicationMailer
  def welcome_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @email = user.email
      @test = user.customer.test

      @title = t('user_mailer.welcome.title')
      @logo_link = user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @confirmation_link = user.customer.reseller.url_protocol + "://" + user.customer.reseller.host + password_user_path(user, token: user.confirmation_token)
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?
      @subscription_duration = user.customer.end_subscription && (user.customer.end_subscription - Date.today).to_i > 1 ? (user.customer.end_subscription - Date.today).to_i : nil

      mail to: @email, subject: t('user_mailer.welcome.subject', name: @name) do |format|
        format.html { render 'user_mailer/welcome', locals: { user: user } }
      end
    end
  end

  def documentation_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @email = user.email

      @help_link = user.customer.reseller.help_url if user.customer.reseller.help_url.present?
      @contact_link = user.customer.reseller.contact_url.gsub('{LG}', I18n.locale.to_s) if user.customer.reseller.contact_url

      @title = t('user_mailer.welcome.title')
      @logo_link = user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?
      @subscription_duration = user.customer.end_subscription && (user.customer.end_subscription - Date.today).to_i > 1 ? (user.customer.end_subscription - Date.today).to_i : nil

      mail to: @email, subject: t('user_mailer.documentation.subject', name: @name) do |format|
        format.html { render 'user_mailer/documentation', locals: { user: user } }
      end
    end
  end
end
