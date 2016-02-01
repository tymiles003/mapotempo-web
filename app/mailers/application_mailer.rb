class ApplicationMailer < ActionMailer::Base
  default from: Mapotempo::Application.config.default_from_mail
  layout 'mailer'
end
