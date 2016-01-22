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

#RestClient.log = $stdout
class AlyacomError < StandardError ; end

module AlyacomApi

  def self.update_staffs(association_id, staffs)
    get = Hash[self.get(association_id, 'staff').select{ |s| s.key?('idExt') }.map{ |s| [s['idExt'], s] }]

    missing = staffs.select{ |s|
      !get.key?(s[:id])
    }.collect{ |s|
      {
        idExt: s[:id],
        firstName: '',
        lastName: s[:name],
        address: s[:street],
        postalCode: s[:postalcode],
        city: s[:city],
      }
    }

    if !missing.empty?
      post(association_id, 'staff', missing)
    end
  end

  def self.update_users(association_id, users)
    get = Hash[self.get(association_id, 'users').select{ |s| s.key?('idExt') }.map{ |s| [s['idExt'], s] }]

    missing = users.select{ |s|
      !get.key?(s[:name])
    }.collect{ |s|
      {
        idExt: s[:id],
        firstName: '',
        lastName: s[:name],
        address: s[:street],
        postalCode: s[:postalcode],
        city: s[:city],
        accessInfo: s[:detail],
        comment: s[:comment],
      }
    }

    if !missing.empty?
      post(association_id, 'users', missing)
    end
  end

  def self.createJobRoute(association_id, date, staff, waypoints)
    update_staffs(association_id, [staff])
    update_users(association_id, waypoints.collect{ |w| w[:user] })

    get = Hash[self.get(association_id, 'planning', fromDate: date.to_time.to_i * 1000, idStaff: staff[:id]).select{ |s| s.key?('idExt') }.map{ |s| [s['idExt'], s] }]

    plannings = waypoints.collect{ |waypoint|
      planning = waypoint[:planning]
      get.delete(planning[:id])

      {
        idExt: planning[:id],
        idStaff: planning[:staff_id],
        idUser: planning[:destination_id],
        comment: planning[:comment] != '' ? planning[:comment] : nil,
        start: planning[:start].strftime('%d/%m/%Y %H:%M'),
        end: planning[:end].strftime('%d/%m/%Y %H:%M'),
      }
    }

    plannings += get.select{ |_k, planning|
      Date.parse(planning['start']) == date
    }.collect{ |_k, planning|
      planning['deleted'] = true
      planning
    }

    post(association_id, 'planning', plannings)
  end

  private

  @base_api_url = Mapotempo::Application.config.alyacom_api_url
  @api_key = Mapotempo::Application.config.alyacom_api_key

  def self.get(association_id, object, params = {})
    url = "#{@base_api_url}/#{association_id}/#{object}"
    get_raw(url, {enc: :json, apiKey: @api_key}.merge(params))
  end

  def self.get_raw(url, params)
    data = []
    next_ = nil
    begin
      begin
        response = RestClient.get(next_ || url, next_ ? nil : {params: params})
      rescue => e
        Rails.logger.info next_ || url
        begin
          # Parse malformed Json, replace key by string, simple quote by double quote
          response = JSON.parse(e.response.gsub('\'', '"').gsub(/([\'\"])?([a-zA-Z0-9_]+)([\'\"])?:/, '"\2":'))
        rescue
          Rails.logger.info e
          raise e
        end
        if !response['message'].blank?
          Rails.logger.info response['message']
          raise AlyacomError.new(response['message'])
        else
          Rails.logger.info e
          raise e
        end
      end
      response = JSON.parse(response)
      data += response['data']
      next_ = response['next']
    end while !next_.nil?
    data
  end

  def self.post(association_id, object, data)
    url = "#{@base_api_url}/#{association_id}/#{object}"
    response = RestClient.post(url, data.to_json, content_type: :json, params: {enc: :json, apiKey: @api_key})
  rescue => e
    Rails.logger.info e.response
    raise e
  end
end
