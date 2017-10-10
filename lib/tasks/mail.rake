namespace :mail do
  task automation: :environment do
    desc 'just send some mail at defined time'
    begin
      users = User.where(created_at: (Time.now.midnight - 15.days)..Time.now.midnight).select { |user|
        true if /https?:\/\/www.mapotempo.com\/[^\/]+\/help-center/.match(user.customer.reseller.help_url) && /https?:\/\/www.mapotempo.com\/[^\/]+\/contact-support/.match(user.customer.reseller.contact_url)
      }

      users.each do |user|
        date = user.created_at.midnight

        case DateTime.now.in_time_zone.midnight
          when date + 1.days
            UserMailer.automation_dispatcher(user, I18n.locale, 'accompanying_team').deliver! # 3
          when date + 2.days
            UserMailer.automation_dispatcher(user, I18n.locale, 'features', true).deliver! # 4
          when date + 3.days
            UserMailer.automation_dispatcher(user, I18n.locale, 'advanced_options', true).deliver! # 5
          when date + 9.days
            UserMailer.accompanying_message(user, I18n.locale).deliver!
          when user.customer.end_subscription.midnight - 1.days
            UserMailer.subscribe_message(user, I18n.locale).deliver! if user.customer.test
          else
            # Silence is golden
        end
      end

    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      raise Exceptions::MailerError.new(e)
    end
  end
end
