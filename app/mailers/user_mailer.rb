class UserMailer < ApplicationMailer
  def welcome_message user
    mail to: user.email, subject: t("user_mailer.welcome.title") do |format|
      format.html { render 'user_mailer/welcome', locals: { user: user } }
    end
  end
end
