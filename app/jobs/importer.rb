require 'geocoder_job'

class Importer

  def self.import(current_user, file, name)
    if Opentour::Application.config.delayed_job_use and current_user.job_geocoding
      return false
    end

    tags = Hash[current_user.tags.collect{ |tag| [tag.label, tag] }]
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
      delayed_job = false
      current_user.destinations.destroy_all

      CSV.foreach(file, col_sep: separator, headers: true) { |row|
        r = row.to_hash.select{ |k|
          ["name", "street", "postalcode", "city", "lat", "lng"].include?(k)
        }
        if decimal == ','
          r["lat"].gsub!(',', '.')
          r["lng"].gsub!(',', '.')
        end
        destination = Destination.new(r)
        destination.user = current_user

        if row["tags"]
          destination.tags = row["tags"].split(',').collect { |key|
            if not tags.key?(key)
              current_user.tags << tags[key] = Tag.new(label: key, user: current_user)
            end
            tags[key]
          }
        end

        routes[row.key?("route")? row["route"] : nil] << destination

        if not(destination.lat and destination.lng)
          if not Opentour::Application.config.delayed_job_use
            destination.geocode
          else
            delayed_job = true
          end
        end

        current_user.destinations << destination
      }

      if routes.size > 1
        planning = Planning.new(name: name)
        planning.user = current_user
        planning.set_destinations(routes.values)
        current_user.plannings << planning
      end

      if delayed_job
        job = Delayed::Job.enqueue(GeocoderJob.new(current_user.id))
        current_user.job_geocoding = job
      end
    end

    return true
  end

end
