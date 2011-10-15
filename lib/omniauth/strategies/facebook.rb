require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Facebook < OmniAuth::Strategies::OAuth2
      include OmniAuth::Strategy
    end
  end
end
