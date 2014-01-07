require 'rest_client'

module Ort

  @cache = Mapotempo::Application.config.optimize_cache
  @url = Mapotempo::Application.config.optimize_url

  def self.optimize(capacity, matrix, time_window)
    key = {capacity: capacity, matrix: matrix, time_window: time_window}.to_json

    result = @cache.read(key)
    if !result
      result = RestClient.post @url, data: key, content_type: :json, accept: :json
      @cache.write(key, result)
    end

    jdata = JSON.parse(result)
    jdata['optim']
  end
end
