require 'open-uri'
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
        url = "#{@osrm_url}/viaroute?loc=#{from_lat},#{from_lng}&loc=#{to_lat},#{to_lng}&alt=false&output=json"
        Rails.logger.info "get #{url}"
        request = JSON.parse(open(url).read)
        @cache_request.set(key, request)
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
