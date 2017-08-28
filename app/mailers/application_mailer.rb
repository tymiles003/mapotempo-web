class ApplicationMailer < ActionMailer::Base
  add_template_helper(EmailHelper)

  default from: Mapotempo::Application.config.default_from_mail
  layout 'mailer'
end
