require 'uri'
require 'net/http'
require 'open-uri'
require 'json'

require 'filecache'

require 'rexml/document'
include REXML

module Geocode

  @cache_dir = Mapotempo::Application.config.geocode_cache_dir
  @cache_delay = Mapotempo::Application.config.geocode_cache_delay
  @ign_referer = Mapotempo::Application.config.geocode_ign_referer
  @ign_key = Mapotempo::Application.config.geocode_ign_key

  @cache = FileCache.new("cache", @cache_dir, @cache_delay, 3)

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
      url = URI.parse("http://gpp3-wxs.ign.fr/#{@ign_key}/geoportail/ols")
      http = Net::HTTP.new(url.host)
      request = Net::HTTP::Post.new(url.path)
      request['Referer'] = @ign_referer
      request['Content-Type'] = 'application/xml'
      request.body = "<?xml version='1.0' encoding='UTF-8'?>
<XLS
    xmlns:xls='http://www.opengis.net/xls'
    xmlns:gml='http://www.opengis.net/gml'
    xmlns='http://www.opengis.net/xls'
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
    version='1.2'
    xsi:schemaLocation='http://www.opengis.net/xls http://schemas.opengis.net/ols/1.2/olsAll.xsd'>
  <RequestHeader/>
  <Request requestID='1' version='1.2' methodName='LocationUtilityService'>
   <GeocodeRequest returnFreeForm='false'>
     <Address countryCode='StreetAddress'>
       <StreetAddress>
         <Street>#{street.encode(xml: :text)}</Street>
       </StreetAddress>
       <Place type='Municipality'>#{city.encode(xml: :text)}</Place>
       <PostalCode>#{postalcode.encode(xml: :text)}</PostalCode>
     </Address>
   </GeocodeRequest>
  </Request>
</XLS>"

      response = http.request(request)
      if response.code == "200"
        result = response.body # => The body (HTML, XML, blob, whatever)
        @cache.set(key, result)
      else
        Rails.logger.info request.body
        Rails.logger.info response.code
        Rails.logger.info response.body
        return
      end
    end

    doc = Document.new(result)
    root = doc.root
    pos = root.elements['Response'].elements['GeocodeResponse'].elements['GeocodeResponseList'].elements['GeocodedAddress'].elements['gml:Point'].elements['gml:pos'].text
    pos = pos.split(' ')

    {lat: pos[0], lng: pos[1]}
  end
end
