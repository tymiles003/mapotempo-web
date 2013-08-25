class GeocoderJob < Struct.new(:customer_id)
  def perform
    customer = Customer.find(customer_id)
    Delayed::Worker.logger.info "GeocoderJob customer_id=#{customer_id} perform"
    count = Destination.where(customer_id: customer_id, lat: nil).count
    i = 0
    Destination.where(customer_id: customer_id, lat: nil).each_slice(50){ |destinations|
      Destination.transaction do
        destinations.each { |destination|
          destination.geocode
          Delayed::Worker.logger.info destination.inspect
          destination.save
          i += 1
        }
        customer.job_geocoding.progress = Integer(i * 100 / count)
        customer.job_geocoding.save
        Delayed::Worker.logger.info "GeocoderJob customer_id=#{customer_id} #{customer.job_geocoding.progress}%"
      end
    }
  end
end
