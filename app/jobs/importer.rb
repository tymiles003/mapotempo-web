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
require 'csv'
require 'geocoder_job'

class Importer

  def self.import(replace, customer, file, name)
    if Mapotempo::Application.config.delayed_job_use && customer.job_geocoding
      return false
    end

    tags = Hash[customer.tags.collect{ |tag| [tag.label, tag] }]
    common_tags = nil
    routes = Hash.new{ |h, k| h[k] = [] }

    contents = File.open(file, 'r:bom|utf-8').read
    if !contents.valid_encoding?
      detection = CharlockHolmes::EncodingDetector.detect(contents)
      if !contents || !detection[:encoding]
        raise I18n.t('destinations.import_file.not_csv')
      end
      contents = CharlockHolmes::Converter.convert(contents, detection[:encoding], 'UTF-8')
    end

    separator = ','
    line = contents.lines.first
    splitComma, splitSemicolon, splitTab = line.split(','), line.split(';'), line.split("\t")
    split, separator = [[splitComma, ',', splitComma.size], [splitSemicolon, ';', splitSemicolon.size], [splitTab, "\t", splitTab.size]].max{ |a, b| a[2] <=> b[2] }

    planning = nil
    need_geocode = false

    Destination.transaction do

      line = 1
      errors = []
      destinations = []
      columns = {
        'ref' => I18n.t('destinations.import_file.ref'),
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
        'take_over' => I18n.t('destinations.import_file.take_over'),
        'quantity' => I18n.t('destinations.import_file.quantity'),
        'active' => I18n.t('destinations.import_file.active')
      }
      columns_name = columns.keys - ['route', 'tags', 'active']

      if replace
        customer.destinations.destroy_all
      end

      CSV.parse(contents, col_sep: separator, headers: false) { |row|
        r = []
        columns.each{ |k, v|
          if row.include?(v)
            r << k
          end
        }
        row = r

        if !row.include?('name') || !(row.include?('city') || row.include?('postalcode') || (row.include?('lat') && row.include?('lng')))
          errors << I18n.t('destinations.import_file.missing_header')
        end
        break
      }

      errors.empty? && CSV.parse(contents, col_sep: separator, headers: true) { |row|
        row = row.to_hash

        line += 1
        if errors.length > 10
          errors << I18n.t('destinations.import_file.too_many_errors')
          break
        end

        # Switch from locale to internal column name
        r = {}
        columns.each{ |k, v|
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

        if !r.key?('name') || !(r.key?('city') || r.key?('postalcode') || (r.key?('lat') && r.key?('lng')))
          errors << I18n.t('destinations.import_file.missing_data', line: line)
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

        if row['tags']
          r['tags'] = row['tags'].split(',').select { |key|
            not key.empty?
          }.collect { |key|
            if not tags.key?(key)
              tags[key] = customer.tags.build(label: key)
            end
            tags[key]
          }
        end

        if r.key?('ref') && !r['ref'].strip.empty?
          destination = customer.destinations.find{ |destination|
            destination.ref && destination.ref == r['ref']
          }
          destination.assign_attributes(r) if destination
        end
        if !destination
          destination = customer.destinations.build(r) # Link only when destination is complete
        end

        # Instersection of tags of all rows
        if !common_tags
          common_tags = destination.tags.to_a
        else
          common_tags &= destination.tags
        end

        routes[row.key?('route') ? row['route'] : nil] << [destination, !row.key?('active') || row['active'].strip != '0']
      }

      if errors.length > 0
        raise errors.join(' ')
      end

      if need_geocode && !Mapotempo::Application.config.delayed_job_use
        routes.each{ |key, destinations|
          destinations.each{ |destination_active|
            if destination_active[0].lat.nil? || destination_active[0].lng.nil?
              begin
                destination_active[0].geocode
              rescue
              end
            end
          }
        }
      end

      if routes.size > 1 || !routes.key?(nil)
        planning = customer.plannings.build(name: name, tags: common_tags || [])
        planning.set_destinations(routes, false)
        planning.save!
      end

      customer.save!
    end


    if need_geocode && Mapotempo::Application.config.delayed_job_use
      customer.job_geocoding = Delayed::Job.enqueue(GeocoderJob.new(customer.id, planning ? planning.id : nil))
    else
      planning.compute if planning
    end

    customer.save!
    true
  end

end
