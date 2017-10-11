class UserMailer < ApplicationMailer

  attr_accessor :links

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

      @logo_link = user.customer.reseller.logo_small.url || user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      mail to: @email, from: "#{@name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.password.subject', name: @name) do |format|
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

      @logo_link = user.customer.reseller.logo_small.url || user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      mail to: @email, from: "#{@name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.connection.subject', name: @name) do |format|
        format.html { render 'user_mailer/connection', locals: { user: user } }
      end
    end
  end

  def accompanying_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @application_name = user.customer.reseller.application_name || @name
      @email = user.email

      @title = t('user_mailer.connection.title')
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host

      @logo_link = user.customer.reseller.logo_small.url || user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      @contact_url = user.customer.reseller.contact_url
      @contact_url.sub! '{LG}', I18n.locale.to_s

      mail to: @email, from: "#{@application_name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.accompanying_second.title') do |format|
        format.html { render 'user_mailer/accompanying', locals: { user: user } }
      end
    end
  end

  def subscribe_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @application_name = user.customer.reseller.application_name || @name
      @email = user.email

      @title = t('user_mailer.connection.title')
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host

      @logo_link = user.customer.reseller.logo_small.url || user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      mail to: @email, from: "#{@application_name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.subscribe_message.title') do |format|
        format.html { render 'user_mailer/subscribe', locals: { user: user } }
      end
    end
  end

  def automation_dispatcher(user, locale, template = 'accompanying_team', links = false)
    I18n.with_locale(locale) do
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @name = user.customer.reseller.name
      @application_name = user.customer.reseller.application_name || @name
      @template = template
      @email = user.email

      @help_url = user.customer.reseller.help_url
      @help_url.sub! '{LG}', I18n.locale.to_s

      @contact_url = user.customer.reseller.contact_url
      @contact_url.sub! '{LG}', I18n.locale.to_s

      @logo_link = user.customer.reseller.logo_small.url || user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      @links = links

      subject = t("user_mailer.#{template}.panels_header")

      mail to: @email, from: "#{@application_name} <#{Rails.application.config.default_from_mail}>", subject: subject do |format|
        format.html { render 'user_mailer/documentation_base', locals: {user: user } }
      end
    end
  end
end
