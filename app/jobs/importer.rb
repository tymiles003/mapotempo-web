require 'geocoder_job'

class Importer

  def self.import(replace, customer, file, name)
    if Mapotempo::Application.config.delayed_job_use and customer.job_geocoding
      return false
    end

    tags = Hash[customer.tags.collect{ |tag| [tag.label, tag] }]
    routes = Hash.new{ |h,k| h[k] = [] }

    separator = ','
    decimal = '.'
    File.open(file) do |f|
      line = f.readline
      splitComma, splitSemicolon = line.split(','), line.split(';')
      split, separator = splitComma.size() > splitSemicolon.size() ? [splitComma, ','] : [splitSemicolon, ';']

      csv = CSV.open(file, col_sep: separator, headers: true)
      row = csv.readline
      ilat = row.index('lat')
      row = csv.readline
      if ilat
        data = row[ilat]
        decimal = data.split('.').size > data.split(',').size ? '.' : ','
      end
    end

    Destination.transaction do
      if replace
        customer.destinations.destroy_all
      end

      line = 1
      errors = []
      columns = {
        'route' => I18n.t('destinations.import_file.route'),
        'name' => I18n.t('destinations.import_file.name'),
        'street' => I18n.t('destinations.import_file.street'),
        'postalcode' => I18n.t('destinations.import_file.postalcode'),
        'city' => I18n.t('destinations.import_file.city'),
        'lat' => I18n.t('destinations.import_file.lat'),
        'lng' => I18n.t('destinations.import_file.lng'),
        'tags' => I18n.t('destinations.import_file.tags')
      }
      CSV.foreach(file, col_sep: separator, headers: true) { |row|
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
          ["name", "street", "postalcode", "city", "lat", "lng"].include?(k)
        }
        if !r.key?('name') or !r.key?('street') or !r.key?('city')
          errors << I18n.t('destinations.import_file.missing_name_street_city', line: line)
          next
        end

        if decimal == ','
          r["lat"].gsub!(',', '.')
          r["lng"].gsub!(',', '.')
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

        customer.destinations << destination
      }

      if errors.length > 0
        raise errors.join(' ')
      end

      if replace
        if routes.size > 1
          planning = Planning.new(name: name)
          planning.customer = customer
          planning.set_destinations(routes.values)
          customer.plannings << planning
        end
      else
        customer.plannings.each { |planning|
          routes[nil].each{ |destination|
            planning.destination_add(destination)
          }
        }
      end

      if not Mapotempo::Application.config.delayed_job_use
        routes.each{ |key, destinations|
          destinations.each{ |destination|
            if not(destination.lat and destination.lng)
              destination.geocode
            end
          }
        }
      else
        customer.job_geocoding = Delayed::Job.enqueue(GeocoderJob.new(customer.id))
      end
    end

    return true
  end

end
