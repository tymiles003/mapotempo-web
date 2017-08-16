class UserMailer < ApplicationMailer
  def welcome_message(user, locale)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name

      @title = t('user_mailer.welcome.title')
      @confirmation_link = user.customer.reseller.url_protocol + "://" + user.customer.reseller.host + password_user_path(user, token: user.confirmation_token)
      @home_link = user.customer.reseller.url_protocol + "://" + user.customer.reseller.host
      @contact_link = (user.customer.reseller.contact_url && user.customer.reseller.contact_url.gsub('{LG}', I18n.locale.to_s))
      @subscription_duration = user.customer.end_subscription && (user.customer.end_subscription - Date.today).to_i > 1 ? (user.customer.end_subscription - Date.today).to_i : 15

      mail to: user.email, subject: t('user_mailer.welcome.subject', name: @name) do |format|
        format.html { render 'user_mailer/welcome', locals: { user: user } }
      end
    end
  end
end
