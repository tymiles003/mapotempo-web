class RouteMailer < ApplicationMailer
  def send_kmz_route user, vehicle, route, filename, attachment
    attachments[filename] = { transfer_encoding: :binary, content: attachment.force_encoding('BINARY') }
    mail from: user.email, to: vehicle.contact_email, subject: "[#{user.customer.reseller.name}] #{filename}" do |format|
      format.text { render 'route_mailer/send_kmz_route', locals: { vehicle: vehicle, route: route } }
    end
  end
end
