# frozen_string_literal: true

module RubyLLM
  module Providers
    module DeepSeek
      # Chat methods of the DeepSeek API integration
      module Chat
        module_function

        def format_role(role)
          # DeepSeek doesn't use the new OpenAI convention for system prompts
          role.to_s
        end

        def render_payload(messages, tools:, temperature:, model:, stream: false)
          {
            model: model,
            messages: format_messages(messages),
            temperature: temperature,
            stream: stream
          }.tap do |payload|
            add_response_schema_to_payload(payload) if response_schema.present?
          end
        end

        private

        def add_response_schema_to_payload(payload)
          payload[:response_format] = { type: 'json_object' }
        end
      end
    end
  end
end
