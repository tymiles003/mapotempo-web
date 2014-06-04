# Copyright © Mapotempo, 2013-2014
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
require 'geocoder_job'

class Importer

  def self.import(replace, customer, file, name)
    if Mapotempo::Application.config.delayed_job_use and customer.job_geocoding
      return false
    end

    tags = Hash[customer.tags.collect{ |tag| [tag.label, tag] }]
    routes = Hash.new{ |h,k| h[k] = [] }

    contents = File.open(file, "r:bom|utf-8").read
    detection = CharlockHolmes::EncodingDetector.detect(contents)
    if !contents || !detection[:encoding]
      raise I18n.t('destinations.import_file.not_csv')
    end
    contents = CharlockHolmes::Converter.convert(contents, detection[:encoding], 'UTF-8')

    separator = ','
    line = contents.lines.first
    splitComma, splitSemicolon = line.split(','), line.split(';')
    split, separator = splitComma.size() > splitSemicolon.size() ? [splitComma, ','] : [splitSemicolon, ';']

    planning = nil
    need_geocode = false

    Destination.transaction do

      line = 1
      errors = []
      destinations = []
      columns = {
        'route' => I18n.t('destinations.import_file.route'),
        'name' => I18n.t('destinations.import_file.name'),
        'street' => I18n.t('destinations.import_file.street'),
        'detail' => I18n.t('destinations.import_file.detail'),
        'postalcode' => I18n.t('destinations.import_file.postalcode'),
        'city' => I18n.t('destinations.import_file.city'),
        'lat' => I18n.t('destinations.import_file.lat'),
        'lng' => I18n.t('destinations.import_file.lng'),
        'open' => I18n.t('destinations.import_file.open'),
        'close' => I18n.t('destinations.import_file.close'),
        'comment' => I18n.t('destinations.import_file.comment'),
        'tags' => I18n.t('destinations.import_file.tags'),
        'quantity' => I18n.t('destinations.import_file.quantity')
      }
      columns_name = columns.keys - ['route', 'tags']

      CSV.parse(contents, col_sep: separator, headers: false) { |row|
        r = []
        columns.each{ |k,v|
          if row.include?(v)
            r << k
          end
        }
        row = r

        if !row.include?('name') || !row.include?('city')
          errors << I18n.t('destinations.import_file.missing_header_name_city')
        end
        break
      }

      errors.empty? and CSV.parse(contents, col_sep: separator, headers: true) { |row|
        row = row.to_hash

        line += 1
        if errors.length > 10
          errors << I18n.t('destinations.import_file.too_many_errors')
          break
        end

        # Switch from locale to internal column name
        r = {}
        columns.each{ |k,v|
          if row.key?(v) && row[v]
            r[k] = row[v]
          end
        }
        row = r

        r = row.to_hash.select{ |k|
          columns_name.include?(k)
        }

        if r.size == 0
          next # Skip empty line
        end

        if !r.key?('name') || !r.key?('city')
          errors << I18n.t('destinations.import_file.missing_name_city', line: line)
          next
        end

        if !r.key?('lat') || !r.key?('lng')
          need_geocode = true
        end

        if r.key?('lat')
          r['lat'].gsub!(',', '.')
        end
        if r.key?('lng')
          r['lng'].gsub!(',', '.')
        end
        destination = Destination.new(r)
        destination.customer = customer

        if row["tags"]
          destination.tags = row["tags"].split(',').select { |key|
            not key.empty?
          }.collect { |key|
            if not tags.key?(key)
              customer.tags << tags[key] = Tag.new(label: key, customer: customer)
            end
            tags[key]
          }
        end

        routes[row.key?("route")? row["route"] : nil] << destination

        destinations << destination
      }

      if errors.length > 0
        raise errors.join(' ')
      end

      if need_geocode && ! Mapotempo::Application.config.delayed_job_use
        routes.each{ |key, destinations|
          destinations.each{ |destination|
            if not(destination.lat and destination.lng)
              begin
                destination.geocode
              rescue StandardError => e
              end
            end
          }
        }
      end

      if replace
        customer.destinations.destroy_all
        customer.destinations += destinations
      else
        destinations.each { |destination|
          customer.destination_add(destination)
        }
      end

      if routes.size > 1 || !routes.key?(nil)
        planning = Planning.new(name: name)
        planning.customer = customer
        planning.set_destinations(routes.values)
        customer.plannings << planning
      end
    end

    if need_geocode && Mapotempo::Application.config.delayed_job_use
      customer.job_geocoding = Delayed::Job.enqueue(GeocoderJob.new(customer.id, planning ? planning.id : nil))
    end

    return true
  end

end
