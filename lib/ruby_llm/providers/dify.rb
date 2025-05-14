# frozen_string_literal: true

module RubyLLM
  module Providers
    # Dify API integration.
    class Dify < Provider
      include Dify::Chat
      include Dify::Streaming

      def api_base
        @config.dify_api_base
      end

      def parse_error(response)
        return if response.body.empty?

        body = try_parse_json(response.body)
        case body
        when Hash
          body['message']
        else
          body
        end
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.dify_api_key}"
        }
      end

      class << self
        def capabilities
          Dify::Capabilities
        end

        def local?
          true
        end

        def configuration_requirements
          %i[dify_api_base dify_api_key]
        end
      end
    end
  end
end
