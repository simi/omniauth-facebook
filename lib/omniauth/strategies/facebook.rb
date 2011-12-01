require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Facebook < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = 'email,offline_access'
      
      option :client_options, {
        :site => 'https://graph.facebook.com',
        :token_url => '/oauth/access_token'
      }

      option :token_params, {
        :parse => :query
      }

      option :access_token_options, {
        :header_format => 'OAuth %s',
        :param_name => 'access_token'
      }
      
      option :authorize_options, [:scope, :display]
      
      uid { raw_info['id'] }
      
      info do
        prune!({
          'nickname' => raw_info['username'],
          'email' => raw_info['email'],
          'name' => raw_info['name'],
          'first_name' => raw_info['first_name'],
          'last_name' => raw_info['last_name'],
          'image' => "http://graph.facebook.com/#{uid}/picture?type=square",
          'description' => raw_info['bio'],
          'urls' => {
            'Facebook' => raw_info['link'],
            'Website' => raw_info['website']
          },
          'location' => (raw_info['location'] || {})['name']
        })
      end
      
      credentials do
        prune!({
          'expires' => access_token.expires?,
          'expires_at' => access_token.expires_at
        })
      end
      
      extra do
        prune!({
          'raw_info' => raw_info
        })
      end
      
      def raw_info
        @raw_info ||= access_token.get('/me').parsed
      end

      def callback_url
        if options.authorize_options.respond_to? :callback_url
          options.authorize_options.callback_url
        else
          super
        end
      end

      def build_access_token
        with_code(request.params['code'] || signed_request && signed_request['code']) do
          super.tap do |token|
            token.options.merge!(access_token_options)
          end
        end
      end

      def access_token_options
        options.access_token_options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
      end
      
      def authorize_params
        super.tap do |params|
          params.merge!(:display => request.params['display']) if request.params['display']
          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      def signed_request
        @signed_request ||= begin
          cookie = request.cookies["fbsr_#{client.id}"] and
          parse_signed_request(cookie)
        end
      end
      
      private
      
      def with_code(code)
        original_code = request.params['code']
        begin
          request.params['code'] = code
          yield
        ensure
          request.params['code'] = original_code
        end
      end
      
      def prune!(hash)
        hash.delete_if do |_, value| 
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
      
      def parse_signed_request(value)
        signature, encoded_payload = value.split('.')

        decoded_hex_signature = base64_decode_url(signature)#.unpack('H*')
        decoded_payload = MultiJson.decode(base64_decode_url(encoded_payload))

        unless decoded_payload['algorithm'] == 'HMAC-SHA256'
          raise NotImplementedError, "unkown algorithm: #{decoded_payload['algorithm']}"
        end

        if valid_signature?(client.secret, decoded_hex_signature, encoded_payload)
          decoded_payload
        end
      end

      def valid_signature?(secret, signature, payload, algorithm = OpenSSL::Digest::SHA256.new)
        OpenSSL::HMAC.digest(algorithm, secret, payload) == signature
      end

      def base64_decode_url(value)
        value += '=' * (4 - value.size.modulo(4))
        Base64.decode64(value.tr('-_', '+/'))
      end
    end
  end
end
