require 'uri'
require 'open-uri'
require 'json'

require 'filecache'

module Geocode

  @cache = FileCache.new("cache", "/tmp/geocode", 60*60*24*10, 3)

  def self.reverse(lat, lng)
    key = "reverse #{lat} #{lng}"

    result = @cache.get(key)
    if !result
      url="http://services.gisgraphy.com/street/streetsearch?format=json&lat=#{lat}&lng=#{lng}&from=1&to=1" # FIXME filtrer les types de route, mais coment ?
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache.set(key, result)
    end

    [result["result"][0]["name"], "0", result["result"][0]["isIn"]]
  end

  def self.complete(lat, lng, radius, street, postalcode, city)
    key = "complete #{lat} #{lng} #{radius} #{street} #{postalcode} #{city}"

    result = @cache.get(key)
    if !result
      url = URI::HTTP.build(:host => "services.gisgraphy.com", :path => "/street/streetsearch", :query => {
        :format => "json",
        :lat => lat,
        :lng => lng,
        :from => 1,
        :to => 20,
        :radius => radius,
#        :name => "#{street}, #{postalcode} #{city}",
        :name => street,
      }.to_query)
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache.set(key, result)
    end

    result["result"].collect{ |r|
      [r["name"], "0", r["isIn"]]
    }
  end

  def self.code(street, postalcode, city)
    key = "code #{street} #{postalcode} #{city}"

    result = @cache.get(key)
    if !result
      url = URI::HTTP.build(:host => "services.gisgraphy.com", :path => "/geocoding/geocode", :query => {
        :format => "json",
        :country => "FR", # FIXME à param
        :postal => true,
        :address => "#{street}, #{postalcode} #{city}",
      }.to_query)
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache.set(key, result)
    end

    result["result"]
  end
end
