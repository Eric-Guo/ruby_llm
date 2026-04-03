# frozen_string_literal: true

module RubyLLM
  module Providers
    class Dify
      # Chat methods of the Dify API integration
      module Chat
        def upload_document(document_path, original_filename = nil)
          path_like = if document_path.respond_to?(:path)
                        document_path.path
                      elsif document_path.respond_to?(:to_path)
                        document_path.to_path
                      else
                        document_path
                      end
          pn = Pathname.new(path_like)
          mime_type = RubyLLM::MimeType.for pn
          original_filename ||= if document_path.respond_to?(:original_filename)
                                  document_path.original_filename
                                else
                                  pn.basename.to_s
                                end
          payload = {
            file: Faraday::Multipart::FilePart.new(path_like, mime_type, original_filename),
            user: 'dify-user'
          }
          @connection.upload('v1/files/upload', payload)
        end
        
        module_function

        def completion_url
          'v1/chat-messages'
        end

        def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil, thinking: nil) # rubocop:disable Lint/UnusedMethodArgument
          only_message_content = messages[0].content # only support first message now
          payload = {
            inputs: {},
            query: only_message_content.is_a?(Content) ? only_message_content.text : only_message_content,
            response_mode: (stream ? 'streaming' : 'blocking'),
            conversation_id: '',
            user: 'dify-user',
            files: format_files(only_message_content)
          }
          payload
        end

        def parse_completion_response(response)
          data = response.body

          Message.new(
            role: :assistant,
            content: data['answer'],
            tool_calls: nil,
            input_tokens: data.dig('metadata', 'usage', 'prompt_tokens'),
            output_tokens: data.dig('metadata', 'usage', 'completion_tokens'),
            model_id: 'dify-model'
          )
        end
      end
    end
  end
end
