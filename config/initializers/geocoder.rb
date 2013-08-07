Geocoder::Configuration.lookup = :nominatim
Geocoder::Configuration.cache = FileCache.new("cache", "/tmp/geocoder", 60*60*24*10, 3)
