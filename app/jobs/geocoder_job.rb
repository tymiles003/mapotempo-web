class GeocoderJob < Struct.new(:user_id)
  def perform
    user = User.find(user_id)
    Delayed::Worker.logger.info "GeocoderJob user_id=#{user_id} perform"
    count = Destination.where(user_id: user_id, lat: nil).count
    i = 0
    Destination.where(user_id: user_id, lat: nil).each_slice(50){ |destinations|
      Destination.transaction do
        destinations.each { |destination|
          destination.geocode
          Delayed::Worker.logger.info destination.inspect
          destination.save
          i += 1
        }
        user.job_geocoding.progress = Integer(i * 100 / count)
        user.job_geocoding.save
        Delayed::Worker.logger.info "GeocoderJob user_id=#{user_id} #{user.job_geocoding.progress}%"
      end
    }
  end
end
