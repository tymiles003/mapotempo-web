class RouteMailer < ApplicationMailer
  def send_kmz_route user, locale, vehicle, route, filename, attachment
    I18n.with_locale(locale) do
      attachments[filename] = { transfer_encoding: :binary, content: attachment.force_encoding('BINARY') }
      mail from: user.email, to: vehicle.contact_email, subject: "[#{user.customer.reseller.name}] #{filename}" do |format|
        format.text { render 'route_mailer/send_kmz_route', locals: { vehicle: vehicle, route: route } }
      end
    end
  end
  def send_ics_route user, locale, vehicle, route, filename, url
    I18n.with_locale(locale) do
      mail from: user.email, to: vehicle.contact_email, subject: "[#{user.customer.reseller.name}] #{filename}" do |format|
        format.text { render 'route_mailer/send_ics_route', locals: { user: user, vehicle: vehicle, route: route, url: url } }
      end
    end
  end
end
