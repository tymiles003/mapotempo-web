namespace :mail do
  task automation: :environment do
    desc 'just send some mail at defined time'
    begin
      users = User.where(created_at: (Time.now.midnight - 15.days)..Time.now.midnight).select { |user|
        true if /https?:\/\/www.mapotempo.com\/[^\/]+\/help-center/.match(user.customer.reseller.help_url)
      }

      UserMailer.mail_automation(users)
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      raise Exception::MailerErrors.new(e)
    end
  end
end
