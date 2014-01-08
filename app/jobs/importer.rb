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
    contents = CharlockHolmes::Converter.convert(contents, detection[:encoding], 'UTF-8')

    separator = ','
    line = contents.lines.first
    splitComma, splitSemicolon = line.split(','), line.split(';')
    split, separator = splitComma.size() > splitSemicolon.size() ? [splitComma, ','] : [splitSemicolon, ';']

    Destination.transaction do

      line = 1
      errors = []
      need_geocode = false
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
      CSV.parse(contents, col_sep: separator, headers: true) { |row|
        row = row.to_hash

        # Switch from locale to internal column name
        line += 1
        if errors.length > 10
          errors << I18n.t('destinations.import_file.too_many_errors')
          break
        end

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

        if !r.key?('name') || !r.key?('street') || !r.key?('city')
          errors << I18n.t('destinations.import_file.missing_name_street_city', line: line)
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
          destination.tags = row["tags"].split(',').collect { |key|
            if not tags.key?(key)
              customer.tags << tags[key] = Tag.new(label: key, customer: customer)
            end
            tags[key]
          }
        end

        if replace
          routes[row.key?("route")? row["route"] : nil] << destination
        else
          routes[nil] << destination
        end

        destinations << destination
      }

      if errors.length > 0
        raise errors.join(' ')
      end

      if replace
        customer.destinations.destroy_all
        customer.destinations += destinations
        if routes.size > 1 || !routes.key?(nil)
          planning = Planning.new(name: name)
          planning.customer = customer
          planning.set_destinations(routes.values)
          customer.plannings << planning
        end
      else
        destinations.each { |destination|
          customer.destination_add(destination)
        }
      end

      if need_geocode
        if not Mapotempo::Application.config.delayed_job_use
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
        else
          customer.job_geocoding = Delayed::Job.enqueue(GeocoderJob.new(customer.id))
        end
      end
    end

    return true
  end

end
