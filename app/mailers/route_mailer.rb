class RouteMailer < ApplicationMailer
  def send_kmz_route customer, from, to, filename, kmz
    attachments['kmz'] = {
      mime_type: 'application/vnd.google-earth.kmz',
      transfer_encoding: :binary,
      content: kmz.force_encoding('BINARY'),
      content_disposition: "attachment; filename=\"#{filename}\""
    }
    mail from: from, to: to, subject: "[#{customer.reseller.name}] #{filename}" do |format|
      format.html { render 'route_mailer/send_kmz_route' }
    end
  end
end
