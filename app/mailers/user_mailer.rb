class UserMailer < ApplicationMailer
  def welcome_message user, locale
    I18n.with_locale(locale) do
      mail to: user.email, subject: t("user_mailer.welcome.title", s: user.customer.reseller.name) do |format|
        format.html { render 'user_mailer/welcome', locals: { user: user } }
      end
    end
  end
end
