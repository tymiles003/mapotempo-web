module ApiBase

  def app
    Rails.application
  end

  def api(path, params = {})
    Addressable::Template.new("/api/0.1/#{path}.json{?query*}").expand(query: params.merge(api_key: 'testkey1')).to_s
  end

  def params_for(device, customer)
    device.to_sym unless device.is_a? Symbol
    case device
      when :teksat
        {
          url: customer.devices[device][:url],
          customer_id: customer.devices[device][:customer_id],
          username: customer.devices[device][:username],
          password: customer.devices[device][:password]
        }
      when :tomtom
        {
          account: customer.devices[device][:account],
          user: customer.devices[device][:user],
          password: customer.devices[device][:password]
        }
      when :orange
        {
          user: customer.devices[device][:username],
          password: customer.devices[device][:password]
        }
      else
        raise 'Unknown Device params'
    end
  end
end
