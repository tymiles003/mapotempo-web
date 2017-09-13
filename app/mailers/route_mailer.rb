class RouteMailer < ApplicationMailer

  def send_kmz_route(user, locale, vehicle, route, filename, attachment)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @logo_link = user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      @title = I18n.t('route_mailer.send_kmz_route.title')
      attachments[filename] = { transfer_encoding: :binary, content: attachment.force_encoding('BINARY') }
      mail to: vehicle.contact_email, subject: "[#{user.customer.reseller.name}] #{filename}" do |format|
        format.html { render 'route_mailer/send_kmz_route', locals: { vehicle: vehicle, route: route } }
      end
    end
  end

  def send_computed_ics_route(user, locale, email, vehicles)
    I18n.with_locale(locale) do
      @name = user.customer.reseller.name
      @logo_link = user.customer.reseller.logo_large.url || 'logo_mapotempo.png'
      @facebook_link = user.customer.reseller.facebook_url if user.customer.reseller.facebook_url.present?
      @twitter_link = user.customer.reseller.twitter_url if user.customer.reseller.twitter_url.present?
      @linkedin_link = user.customer.reseller.linkedin_url if user.customer.reseller.linkedin_url.present?

      @title = I18n.t('route_mailer.send_computed_ics_route.title')
      mail to: email, subject: "[#{user.customer.reseller.name}] Export Planning iCalendar" do |format|
        format.html { render 'route_mailer/send_computed_ics_route', locals: { user: user, infos: vehicles } }
      end
    end
  end

end
