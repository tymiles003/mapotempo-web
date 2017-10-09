namespace :mail do
  task automation: :environment do
    desc 'just send some mail at defined time'
    begin
      users = User.where(created_at: (Time.now.midnight - 15.days)..Time.now.midnight).select { |user|
        true if /https?:\/\/www.mapotempo.com\/[^\/]+\/help-center/.match(user.customer.reseller.help_url)
      }

      users.each do |user|
        date = user.created_at.midnight
        UserMailer.links = false

        case DateTime.now.in_time_zone.midnight
          when date + 1.days
            UserMailer.automation_dispatcher(user, I18n.locale, 'accompanying_team').deliver! # 3
          when date + 2.days
            UserMailer.links = true
            UserMailer.automation_dispatcher(user, I18n.locale, 'features').deliver! # 4
          when date + 3.days
            UserMailer.links = true
            UserMailer.automation_dispatcher(user, I18n.locale, 'advanced_options').deliver! # 5
          when date + 9.days
            UserMailer.accompanying_message(user, I18n.locale).deliver!
          when date + 14.days
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
