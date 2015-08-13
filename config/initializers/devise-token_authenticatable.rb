Devise::TokenAuthenticatable.setup do |config|
  # set the authentication key name used by this module,
  # defaults to :auth_token
  config.token_authentication_key = :api_key

  # enable reset of the authentication token before the model is saved,
  # defaults to false
  config.should_reset_authentication_token = false

  # enables the setting of the authentication token - if not already - before the model is saved,
  # defaults to false
  config.should_ensure_authentication_token = false
end

module Devise
  module Models
    module TokenAuthenticatable
      module ClassMethods
        def find_for_token_authentication(conditions)
          auth_conditions = conditions.dup
          authentication_token = auth_conditions.delete(Devise::TokenAuthenticatable.token_authentication_key)

          find_for_authentication(
# Monkey path
# Change data base field name
            auth_conditions.merge(api_key: authentication_token)
# Monkey path
          )
        end
      end
    end
  end
end
