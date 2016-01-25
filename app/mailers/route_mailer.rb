class RouteMailer < ApplicationMailer
  def send_kml_route route, content
    @vehicle = route.vehicle_usage.vehicle
    attachments["route-#{route.id}-#{Time.now.to_i}.kml"] = { mime_type: 'text/xml', content: content }
    mail to: @vehicle.contact_email, subject: t("route_mailer.send_kml_route.subject", n: @vehicle.name) do |format|
      format.html { render "route_mailer/send_kml_route" }
    end
  end
end
