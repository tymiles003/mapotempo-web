class RouteMailer < ApplicationMailer
  def send_kmz_route user, vehicle, route, filename, attachment
    attachments['kmz'] = {
      mime_type: 'application/vnd.google-earth.kmz',
      transfer_encoding: :binary,
      content: attachment.force_encoding('BINARY'),
      content_disposition: "attachment; filename=\"#{filename}\";"
    }
    mail from: user.email, to: vehicle.contact_email, subject: "[#{user.customer.reseller.name}] #{filename}" do |format|
      format.html { render 'route_mailer/send_kmz_route', locals: { vehicle: vehicle, route: route } }
    end
  end
end
