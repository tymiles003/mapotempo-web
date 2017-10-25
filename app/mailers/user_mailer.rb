class UserMailer < ApplicationMailer

  attr_accessor :links

  def password_message(user, locale)
    I18n.with_locale(locale) do
      @name, @application_name = names(user)
      @title = t('user_mailer.password.title')
      @confirmation_link = password_user_url(user, token: user.confirmation_token, host: user.customer.reseller.url_protocol + '://' + user.customer.reseller.host)
      @subscription_duration = user.customer.end_subscription && (user.customer.end_subscription - Date.today).to_i > 1 ? (user.customer.end_subscription - Date.today).to_i : nil
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @logo_link, @facebook_link, @twitter_link, @linkedin_link = social_links(user)

      mail to: user.email, from: "#{@name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.password.subject', name: @name) do |format|
        format.html { render 'user_mailer/password', locals: { user: user } }
      end
    end
  end

  def connection_message(user, locale)
    I18n.with_locale(locale) do
      @name, @application_name = names(user)
      @title = t('user_mailer.connection.title')
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @logo_link, @facebook_link, @twitter_link, @linkedin_link = social_links(user)

      mail to: user.email, from: "#{@name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.connection.subject', name: @name) do |format|
        format.html { render 'user_mailer/connection', locals: { user: user } }
      end
    end
  end

  def accompanying_message(user, locale)
    I18n.with_locale(locale) do
      @name, @application_name = names(user)
      @template = 'accompanying'
      @parameters = links_parameters('accompanying_message', locale)
      @title = t('user_mailer.accompanying.title')
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @logo_link, @facebook_link, @twitter_link, @linkedin_link = social_links(user)
      @contact_url = contact_url(user, locale)

      mail to: user.email, from: "#{@application_name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.accompanying.title') do |format|
        format.html { render 'user_mailer/accompanying', locals: { user: user } }
      end
    end
  end

  def subscribe_message(user, locale)
    I18n.with_locale(locale) do
      @name, @application_name = names(user)
      @template = 'subscribe'
      @parameters = links_parameters('subscribe_message', locale)
      @title = t('user_mailer.subscribe.title')
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @logo_link, @facebook_link, @twitter_link, @linkedin_link = social_links(user)

      mail to: user.email, from: "#{@application_name} <#{Rails.application.config.default_from_mail}>", subject: t('user_mailer.subscribe.title') do |format|
        format.html { render 'user_mailer/subscribe', locals: { user: user } }
      end
    end
  end

  def automation_dispatcher(user, locale, template = 'accompanying_team', links = false)
    I18n.with_locale(locale) do
      @name, @application_name = names(user)
      @home_link = user.customer.reseller.url_protocol + '://' + user.customer.reseller.host
      @template = template
      @help_url = user.customer.reseller.help_url.sub('{LG}', locale.to_s)
      @contact_url = contact_url(user, locale)
      @logo_link, @facebook_link, @twitter_link, @linkedin_link = social_links(user)
      @links = links
      @parameters = links_parameters(template, locale)

      mail to: user.email, from: "#{@application_name} <#{Rails.application.config.default_from_mail}>", subject: t("user_mailer.#{template}.panels_header") do |format|
        format.html { render 'user_mailer/documentation_base', locals: { user: user } }
      end
    end
  end

  private

  def links_parameters(name, locale = :fr)
    Rails.application.config.automation[:parameters][name.to_sym][locale.to_sym]
  end

  def contact_url(user, locale)
    url = user.customer.reseller.contact_url
    url.sub '{LG}', locale.to_s
  end

  def social_links(user)
    logo_link = user.customer.reseller.logo_small.url || user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
    facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
    twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
    linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

    [logo_link, facebook_link, twitter_link, linkedin_link]
  end

  def names(user)
    name = user.customer.reseller.name
    application_name = user.customer.reseller.application_name || name

    [name, application_name]
  end
end
