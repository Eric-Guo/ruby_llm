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

        def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil, thinking: nil) # rubocop:disable Lint/UnusedMethodArgument
          current_message = messages[-1]
          current_message_content = current_message.content # dify using conversation_id to trace message history

          # Find the latest non-nil conversation_id from all messages
          latest_conversation_id = messages.reverse.find { |msg| msg.conversation_id }&.conversation_id

          payload = {
            inputs: {},
            query: current_message_content.is_a?(Content) ? current_message_content.text : current_message_content,
            response_mode: (stream ? 'streaming' : 'blocking'),
            conversation_id: latest_conversation_id,
            user: (@config&.dify_user || 'dify-user'),
            files: format_files(current_message_content)
          }

          payload[:thinking] = { type: 'enabled' } if thinking&.enabled?
          payload
        end

        def parse_completion_response(response)
          data = response.body
          message_data = data.dig('choices', 0, 'message')
          usage = data['usage'] || {}

          if message_data
            content, thinking_from_tags = extract_content_and_thinking(message_data['content'])
            thinking_text = thinking_from_tags || extract_thinking_text(message_data)
            thinking_signature = extract_thinking_signature(message_data)
            thinking_tokens = extract_thinking_tokens(data)
          else
            answer = data['answer']
            content, thinking_from_tags = extract_content_and_thinking(answer)
            thinking_text = thinking_from_tags || extract_thinking_text(data)
            thinking_signature = extract_thinking_signature(data)
            thinking_tokens = extract_thinking_tokens(data)
          end

          Message.new(
            role: :assistant,
            content: content,
            thinking: Thinking.build(text: thinking_text, signature: thinking_signature),
            tool_calls: nil,
            input_tokens: usage['prompt_tokens'] || data.dig('metadata', 'usage', 'prompt_tokens'),
            output_tokens: usage['completion_tokens'] || data.dig('metadata', 'usage', 'completion_tokens'),
            thinking_tokens: thinking_tokens,
            conversation_id: data['conversation_id'],
            model_id: data['model'] || 'dify-model',
            raw: response
          )
        end

        def extract_content_and_thinking(answer)
          return [answer, nil] unless answer.is_a?(String)
          return [answer, nil] unless answer.include?('<think>')

          thinking = answer.scan(%r{<think>(.*?)</think>}m).join
          content = answer.gsub(%r{<think>.*?</think>}m, '').strip

          [content.empty? ? nil : content, thinking.empty? ? nil : thinking]
        end

        def extract_thinking_text(data)
          candidate = data['reasoning_content'] || data['reasoning'] || data['thinking'] || data['thought']
          return candidate if candidate.is_a?(String)

          metadata = data['metadata']
          candidate = metadata&.dig('reasoning_content') ||
                      metadata&.dig('reasoning') ||
                      metadata&.dig('thinking') ||
                      metadata&.dig('thought')
          return candidate if candidate.is_a?(String)

          thoughts = data['thoughts'] || metadata&.dig('thoughts')
          return nil unless thoughts.is_a?(Array)

          text = thoughts.filter_map do |thought|
            next thought if thought.is_a?(String)

            thought['thought'] || thought['thinking'] || thought['content'] || thought['text']
          end.join

          text.empty? ? nil : text
        end

        def extract_thinking_signature(data)
          candidate = data['thinking_signature'] || data['reasoning_signature'] || data['signature']
          return candidate if candidate.is_a?(String)

          metadata = data['metadata']
          candidate = metadata&.dig('thinking_signature') ||
                      metadata&.dig('reasoning_signature') ||
                      metadata&.dig('signature')
          candidate if candidate.is_a?(String)
        end

        def extract_thinking_tokens(data)
          usage = data['usage'] || data.dig('metadata', 'usage') || {}
          usage['thinking_tokens'] ||
            usage['reasoning_tokens'] ||
            usage.dig('completion_tokens_details', 'reasoning_tokens') ||
            usage.dig('output_tokens_details', 'thinking_tokens')
        end
      end
    end
  end
end
