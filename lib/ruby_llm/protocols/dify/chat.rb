# frozen_string_literal: true

module RubyLLM
  module Protocols
    class Dify
      # Chat methods of the Dify API integration
      module Chat
        module_function

        def finish_reasons = {}

        def completion_url
          'v1/chat-messages'
        end

        # rubocop:disable-next Lint/UnusedMethodArgument
        def render_payload(messages, tools:, temperature:, model:, stream: false, max_output_tokens: nil, schema: nil,
                           thinking: nil, tool_prefs: nil, citations: nil, caching: nil)
          current_message = messages[-1]
          current_message_content = current_message.content # dify using conversation_id to trace message history

          # Find the latest non-nil conversation_id from all messages
          latest_conversation_id = messages.reverse.find(&:conversation_id)&.conversation_id

          payload = {
            inputs: {},
            query: current_message_content,
            response_mode: (stream ? 'streaming' : 'blocking'),
            conversation_id: latest_conversation_id,
            user: @config&.dify_user || 'dify-user',
            files: format_files(current_message.attachments)
          }

          payload[:thinking] = { type: 'enabled' } if thinking&.enabled?
          payload
        end

        # rubocop:disable-next Metrics/PerceivedComplexity
        def parse_completion_body(data, raw:)
          message_data = data.dig('choices', 0, 'message')
          usage = data['usage'] || {}

          if message_data
            content, thinking_from_tags = extract_content_and_thinking(message_data['content'])
            thinking_text = thinking_from_tags || extract_thinking_text(message_data)
            thinking_signature = extract_thinking_signature(message_data)
          else
            answer = data['answer']
            content, thinking_from_tags = extract_content_and_thinking(answer)
            thinking_text = thinking_from_tags || extract_thinking_text(data)
            thinking_signature = extract_thinking_signature(data)
          end
          thinking_tokens = extract_thinking_tokens(data)

          Message.new(
            role: :assistant,
            content: content,
            thinking: Thinking.build(text: thinking_text, signature: thinking_signature),
            tool_calls: nil,
            input_tokens: usage['prompt_tokens'] || data.dig('metadata', 'usage', 'prompt_tokens'),
            output_tokens: usage['completion_tokens'] || data.dig('metadata', 'usage', 'completion_tokens'),
            thinking_tokens: thinking_tokens,
            conversation_id: data['conversation_id'],
            model: data['model'] || 'dify-model',
            raw: raw
          )
        end

        def extract_content_and_thinking(answer)
          return [answer, nil] unless answer.is_a?(String)
          return [answer, nil] unless answer.include?('<think>')

          thinking = answer.scan(%r{<think>(.*?)</think>}m).join
          content = answer.gsub(%r{<think>.*?</think>}m, '').strip

          [content.empty? ? nil : content, thinking.empty? ? nil : thinking]
        end

        # rubocop:disable-next Metrics/PerceivedComplexity
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

        def supports_provider_file_references?
          true
        end

        def default_large_file_upload_threshold
          0
        end

        def provider_file_attachable?(attachment)
          attachment.image? || attachment.video? || attachment.audio? || attachment.pdf? ||
            attachment.document? || attachment.text?
        end
      end
    end
  end
end
