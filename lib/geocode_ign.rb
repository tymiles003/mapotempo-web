# Copyright © Mapotempo, 2013-2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'uri'
require 'net/http'
require 'open-uri'
require 'json'

require 'rexml/document'
include REXML

class GeocodeIgn
  MATCHTYPE = {'street number' => 'house', 'street enhanced' => 'street'}.freeze

  def accuracy_success
    0.98
  end

  def accuracy_warning
    0.9
  end

  def initialize(key, referer)
    @ign_key = key
    @ign_referer = referer

    @cache_code = Mapotempo::Application.config.geocode_code_cache
    @cache_reverse = Mapotempo::Application.config.geocode_reverse_cache
    @cache_complete = Mapotempo::Application.config.geocode_complete_cache
  end

  def reverse(lat, lng)
    key = ['ign', lat, lng]

    result = @cache_reverse.read(key)
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
  <Request requestID='1' version='1.2' methodName='ReverseGeocodeRequest' maximumResponses='1'>
    <ReverseGeocodeRequest>
      <Position><gml:Point><gml:pos>#{lat} #{lng}</gml:pos></gml:Point></Position>
      <ReverseGeocodePreference>StreetAddress</ReverseGeocodePreference>
    </ReverseGeocodeRequest>
  </Request>
</XLS>"

      response = http.request(request)
      if response.nil?
        raise 'No connection to the host'
      elsif response.code == '200'
        result = response.body # => The body (HTML, XML, blob, whatever)
        @cache_reverse.write(key, result)
      else
        Rails.logger.info request.body
        Rails.logger.info response.code
        Rails.logger.info response.body
        raise response.body
      end
    end

    begin
      doc = Document.new(result)
      root = doc.root
      pos = root.elements['Response'].elements['ReverseGeocodeResponse'].elements['ReverseGeocodedLocation'].elements['Address']
      building = pos.elements['StreetAddress'].elements['Building'].attribute('number').value
      street = pos.elements['StreetAddress'].elements['Street'].text
      city = pos.elements['Place[@type=\'Commune\']'].text
      postal_code = pos.elements['PostalCode'].text

      if building && !building.empty?
        street = "#{building} #{street}"
      end

      {street: street, postal_code: postal_code, city: city}
    rescue => e
      Rails.logger.info e
      nil
    end
  end

  def complete(street, postalcode, city, country, lat = nil, lng = nil)
    []
  end

  def code(street, postalcode, city, country, lat = nil, lng = nil)
    key = ['ign', street, postalcode, city]

    result = @cache_code.read(key)
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
         <Street>#{street ? street.encode(xml: :text) : ''}</Street>
       </StreetAddress>
       <Place type='Municipality'>#{city ? city.encode(xml: :text) : ''}</Place>
       <PostalCode>#{postalcode ? postalcode.encode(xml: :text) : ''}</PostalCode>
     </Address>
   </GeocodeRequest>
  </Request>
</XLS>"

      response = http.request(request)
      if response.nil?
        raise 'No connection to the host'
      elsif response.code == '200'
        result = response.body # => The body (HTML, XML, blob, whatever)
        @cache_code.write(key, result)
      else
        Rails.logger.info request.body
        Rails.logger.info response.code
        Rails.logger.info response.body
        raise response.body
      end
    end

    begin
      doc = Document.new(result)
      root = doc.root
      geocodedAddress = root.elements['Response'].elements['GeocodeResponse'].elements['GeocodeResponseList'].elements['GeocodedAddress']
      pos = geocodedAddress.elements['gml:Point'].elements['gml:pos'].text
      pos = pos.split(' ')

      geocodeMatchCode = geocodedAddress.elements['GeocodeMatchCode']
      quality = geocodeMatchCode.attribute('matchType').value.downcase
      MATCHTYPE.each { |k, v| quality.gsub!(k, v) }
      accuracy = Float(geocodeMatchCode.attribute('accuracy').value)

      {lat: pos[0], lng: pos[1], quality: quality, accuracy: accuracy}
    rescue => e
      Rails.logger.info e
      nil
    end
  end

  def code_free(q, country, limit = 10, lat = nil, lng = nil)
    key = q

    result = @cache_code.read(key)
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
    <Request maximumResponses='10' methodName='GeocodeRequest' requestID='1' version='1.2'>
      <GeocodeRequest returnFreeForm='true'>
        <Address countryCode='StreetAddress'>
          <freeFormAddress>#{q.encode(xml: :text)}</freeFormAddress>
        </Address>
      </GeocodeRequest>
    </Request>
</XLS>"

      response = http.request(request)
      if response.nil?
        raise 'No connection to the host'
      elsif response.code == '200'
        result = response.body # => The body (HTML, XML, blob, whatever)
        @cache_code.write(key, result)
      else
        Rails.logger.info request.body
        Rails.logger.info response.code
        Rails.logger.info response.body
        raise response.body
      end
    end

    begin
      doc = Document.new(result)
      root = doc.root
      root.elements['Response'].elements['GeocodeResponse'].elements['GeocodeResponseList'].elements.collect{ |geocodedAddress|
        pos = geocodedAddress.elements['gml:Point'].elements['gml:pos'].text
        free = geocodedAddress.elements['Address'].elements['freeFormAddress'].text
        pos = pos.split(' ')

        geocodeMatchCode = geocodedAddress.elements['GeocodeMatchCode']
        matchType = geocodeMatchCode.attribute('matchType').value
        accuracy = Float(geocodeMatchCode.attribute('accuracy').value)

        {lat: pos[0], lng: pos[1], quality: matchType, accuracy: accuracy, free: free}
      }
    rescue => e
      Rails.logger.info e
      nil
    end
  end

  def code_bulk(addresses)
    addresses.collect{ |address|
      begin
        code(*address)
      rescue
      end
    }
  end
end
