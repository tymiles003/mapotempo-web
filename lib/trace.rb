require 'open-uri'
require 'json'

require 'filecache'

module Trace

  @cache_dir = Opentour::Application.config.trace_cache_dir
  @cache_delay = Opentour::Application.config.trace_cache_delay
  @osrm_url = Opentour::Application.config.trace_osrm_url

  @cache = FileCache.new("cache", @cache_dir, @cache_delay, 3)

  def self.compute(from_lat, from_lng, to_lat, to_lng)
    key = "#{from_lat} #{from_lng} #{to_lat} #{to_lng}"

    result = @cache.get(key)
    if !result
      url = "#{@osrm_url}/viaroute?loc=#{from_lat},#{from_lng}&loc=#{to_lat},#{to_lng}&alt=false&output=json"
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache.set(key, result)
    end

    distance = result["route_summary"]["total_distance"]
    time = result["route_summary"]["total_time"]
    trace = result["route_geometry"]
    [distance, time, trace]
  end
end
