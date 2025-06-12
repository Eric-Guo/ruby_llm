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
            user: (@config&.dify_user || 'dify-user')
          }
          @connection.upload('v1/files/upload', payload)
        end
        
        module_function

        def completion_url
          'v1/chat-messages'
        end

        def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil) # rubocop:disable Lint/UnusedMethodArgument
          current_message = messages[-1]
          current_message_content = current_message.content # dify using conversation_id to trace message history

          # Find the latest non-nil conversation_id from all messages
          latest_conversation_id = messages.reverse.find { |msg| msg.conversation_id }&.conversation_id

          {
            inputs: {},
            query: current_message_content.is_a?(Content) ? current_message_content.text : current_message_content,
            response_mode: (stream ? 'streaming' : 'blocking'),
            conversation_id: latest_conversation_id,
            user: (@config&.dify_user || 'dify-user'),
            files: format_files(current_message_content)
          }
        end

        def parse_completion_response(response)
          data = response.body

          Message.new(
            role: :assistant,
            content: data['answer'],
            tool_calls: nil,
            input_tokens: data.dig('metadata', 'usage', 'prompt_tokens'),
            output_tokens: data.dig('metadata', 'usage', 'completion_tokens'),
            conversation_id: data['conversation_id'],
            model_id: 'dify-model',
            raw: response
          )
        end
      end
    end
  end
end
