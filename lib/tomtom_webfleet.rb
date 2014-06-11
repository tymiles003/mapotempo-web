# Copyright © Mapotempo, 2014
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
require 'net/http'
require 'json'


module TomtomWebfleet

  @url = Mapotempo::Application.config.tomtom_api_url

  def self.showObjectReportExtern(account, username, password, lang, group)
    self.get(:showObjectReportExtern, account, username, password, lang, {
      'objectgroup-name' => group,
    })
  end

  def self.clearOrdersExtern(account, username, password, lang, objectuid)
    self.get(:clearOrdersExtern, account, username, password, lang, {
      objectuid: objectuid,
      mark_deleted: 1,
    })
  end

  def self.sendDestinationOrderExtern(account, username, password, lang, objectuid, stop, orderid, description, waypoints = nil)
    params = {
      objectuid: objectuid,
      orderid: orderid,
      ordertext: description.strip[0..499],
      latitude: (stop.destination.lat*1e6).round.to_s,
      longitude: (stop.destination.lng*1e6).round.to_s,
    }
    (params[:ordertime] = stop.time.strftime("%H:%M")) if stop.time
    (params[:zip] = stop.destination.postalcode[0.9]) if stop.destination.postalcode
    (params[:city] = stop.destination.city[0..49]) if stop.destination.city
    (params[:street] = stop.destination.street[0..49]) if stop.destination.street
    if waypoints
      params[:wp] = waypoints.collect{ |waypoint|
        [(waypoint[:lat]*1e6).round.to_s, (waypoint[:lng]*1e6).round.to_s, waypoint[:description].gsub(',', ' ')[0..19]].join(',')
      }
    end
    self.get(:sendDestinationOrderExtern, account, username, password, lang, params)
  end

  private
    def self.get(action, account, username, password, lang, params = {})
      params = {account: account, username: username, password: password, lang: lang, action: action, useUTF8: true, outputformat: :json}.merge(params)
      uri = URI(@url)
      uri.query = URI.encode_www_form(params)
      result = Net::HTTP.get_response(uri)

      if result && result.code != '200'
        raise result.message
      else
        jdata = JSON.parse(result.body)
        if jdata.is_a?(Hash) && jdata['errorMsg']
          Rails::logger.info params.inspect
          raise jdata['errorMsg']
        else
          jdata
        end
      end
    end
end
