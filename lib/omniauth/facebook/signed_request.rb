require 'base64'
require 'openssl'

module OmniAuth
  module Facebook
    class SignedRequest
      class UnknownSignatureAlgorithmError < NotImplementedError; end

      SUPPORTED_ALGORITHM = 'HMAC-SHA256'

      def self.parse_signed_request(value, secret)
        signature, encoded_payload = value.split('.')
        return if signature.nil?

        decoded_hex_signature = base64_decode_url(signature)
        decoded_payload = MultiJson.decode(base64_decode_url(encoded_payload))

        unless decoded_payload['algorithm'] == SUPPORTED_ALGORITHM
          raise UnknownSignatureAlgorithmError, "unknown algorithm: #{decoded_payload['algorithm']}"
        end

        if valid_signature?(secret, decoded_hex_signature, encoded_payload)
          decoded_payload
        end
      end

      def self.valid_signature?(secret, signature, payload, algorithm = OpenSSL::Digest::SHA256.new)
        OpenSSL::HMAC.digest(algorithm, secret, payload) == signature
      end

      def self.base64_decode_url(value)
        value += '=' * (4 - value.size.modulo(4))
        Base64.decode64(value.tr('-_', '+/'))
      end
    end
  end
end
