class RouteMailer < ApplicationMailer

  def send_kmz_route(user, locale, vehicle, route, filename, attachment)
    I18n.with_locale(locale) do
      @title = filename
      attachments[filename] = { transfer_encoding: :binary, content: attachment.force_encoding('BINARY') }
      mail to: vehicle.contact_email, subject: "[#{user.customer.reseller.name}] #{filename}" do |format|
        format.html { render 'route_mailer/send_kmz_route', locals: { vehicle: vehicle, route: route } }
      end
    end
  end

  def send_computed_ics_route(user, locale, email, vehicles)
    @title = 'Export Planning iCalendar'
    I18n.with_locale(locale) do
      mail to: email, subject: "[#{user.customer.reseller.name}] Export Planning iCalendar" do |format|
        format.html { render 'route_mailer/send_computed_ics_route', locals: { user: user, infos: vehicles } }
      end
    end
  end

end
