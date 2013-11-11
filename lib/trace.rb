require 'json'

require 'filecache'

module Trace

  @cache_dir = Mapotempo::Application.config.trace_cache_dir
  @cache_delay = Mapotempo::Application.config.trace_cache_delay
  @osrm_url = Mapotempo::Application.config.trace_osrm_url

  @cache_request = FileCache.new("cache", @cache_dir, @cache_delay, 3)
  @cache_result = FileCache.new("cache", @cache_dir+"_result", @cache_delay, 3)

  def self.compute(from_lat, from_lng, to_lat, to_lng)
    key = "#{from_lat} #{from_lng} #{to_lat} #{to_lng}"

    result = @cache_result.get(key)
    if !result
      request = @cache_request.get(key)
      if !request
        begin
          uri = URI(url = "#{@osrm_url}/viaroute")
          uri.query = "loc=#{from_lat},#{from_lng}&loc=#{to_lat},#{to_lng}&alt=false&output=json"
          Rails.logger.info "get #{uri}"
          res = Net::HTTP.get_response(uri)
          if res.is_a?(Net::HTTPSuccess)
            request = JSON.parse(res.body)
            @cache_request.set(key, request)
          else
            raise http.message
          end
        rescue OpenSSL::SSL::SSLError
          raise "Unable to communicate over SSL"
        rescue Errno::ECONNREFUSED
          raise "Connection was refused"
        rescue Errno::ETIMEDOUT
          raise "Timed out connecting"
        rescue Errno::EHOSTDOWN
          raise "The host not responding to requests"
        rescue Errno::EHOSTUNREACH
          raise "Possible network issue communicating"
        rescue SocketError
          raise "Couldn't make sense of the host destination"
        rescue JSON::ParserError
          raise "The host returned a non-JSON response"
        rescue StandardError => e
          raise e.message
        end
      end

      distance = request["route_summary"]["total_distance"]
      time = request["route_summary"]["total_time"]
      trace = request["route_geometry"]

      result = [distance, time, trace]
      @cache_result.set(key, result)
    end

    result
  end
end
