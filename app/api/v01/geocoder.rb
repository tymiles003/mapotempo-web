require 'geocode'

class V01::Geocoder < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def destination_params
      p = ActionController::Parameters.new(params)
      p = p[:destination] if p.has_key?(:destination)
      p.permit(:q, :json_callback)
    end
  end

  resource :geocoder do
    desc "Geocode."
    get 'search' do
      json = Geocode.code_free(params[:q]).collect{ |result|
        {
          address: {
            city: result[:free]
          },
          boundingbox: [
            result[:lat],
            result[:lat],
            result[:lng],
            result[:lng]
          ],
          display_name: result[:free],
          importance: result[:accuracy],
          lat: result[:lat],
          lon: result[:lng],
        }
      }

      if params[:json_callback]
        content_type "text/plain"
        "#{params[:json_callback]}(#{json.to_json})"
      else
        json
      end
    end
  end
end
