# Copyright © Mapotempo, 2015
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
require 'rest_client'

class GeocodeAddokWrapper
  RESULTTYPE = {'city' => 'city', 'street' => 'street', 'locality' => 'street', 'intersection' => 'intersection', 'house' => 'house', 'poi' => 'house'}

  def accuracy_success
    0.8
  end

  def accuracy_warning
    0.5
  end

  def initialize(url, api_key)
    @url = url
    @api_key = api_key

    @cache_code = Mapotempo::Application.config.geocode_code_cache
  end

  def code(street, postalcode, city, country)
    key = ['addok_wrapper', street, postalcode, city, country]
    result = @cache_code.read(key)
    if !result
      begin
        result = RestClient.get(@url + '/geocode.json', params: {
          api_key: @api_key,
          limit: 1,
          street: street,
          postcode: postalcode,
          city: city,
          country: country
        })

        @cache_code.write(key, result && String.new(result)) # String.new workaround waiting for RestClient 2.0
      rescue
        raise
      end
    end

    data = JSON.parse(result)
    if data['features'].size > 0
      data = data['features'][0]
      score = data['properties']['geocoding']['score']
      type = data['properties']['geocoding']['type']
      coordinates = data['geometry']['coordinates']
      {lat: coordinates[1], lng: coordinates[0], quality: RESULTTYPE[type], accuracy: score}
    end
  end

  def code_free(q, country, limit = 10, lat = nil, lng = nil)
    key = ['addok_wrapper', q]
    result = @cache_code.read(key)
    if !result
      begin
        result = RestClient.get(@url + '/geocode.json', params: {
          api_key: @api_key,
          limit: limit,
          query: q,
          country: country
        })

        @cache_code.write(key, result && String.new(result)) # String.new workaround waiting for RestClient 2.0
      rescue
        raise
      end
    end

    data = JSON.parse(result)
    features = data['features']
    features.collect{ |feature|
      score = feature['properties']['geocoding']['score']
      type = feature['properties']['geocoding']['type']
      label = feature['properties']['geocoding']['label']
      coordinates = feature['geometry']['coordinates']
      {lat: coordinates[1], lng: coordinates[0], quality: RESULTTYPE[type], accuracy: score, free: label}
    }
  end

  def reverse(lat, lng)
  end

  def complete(street, postalcode, city, country, lat = nil, lng = nil)
    []
  end

  def code_bulk(rows)
  end
end
