require 'open-uri'
require 'json'

require 'filecache'

module Trace

  @cache = FileCache.new("cache", "/tmp/trace", 60*60*24*10, 3)

  def self.compute(from_lat, from_lng, to_lat, to_lng)
    key = "#{from_lat} #{from_lng} #{to_lat} #{to_lng}"

    Rails.logger.info @diskcache.inspect
    result = @cache.get(key)
    if !result
      url = "http://router.project-osrm.org/viaroute?loc=#{from_lat},#{from_lng}&loc=#{to_lat},#{to_lng}&alt=false&output=json"
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache.set(key, result)
    end

    distance = result["route_summary"]["total_distance"]
    trace = result["route_geometry"]
    [distance, trace]
  end
end
