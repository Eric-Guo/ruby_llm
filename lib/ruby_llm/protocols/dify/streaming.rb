# frozen_string_literal: true

module RubyLLM
  module Protocols
    class Dify
      # Streaming methods of the Dify API integration
      module Streaming
        module_function

        def stream_url
          completion_url
        end

        def build_chunk(data)
          attributes = data['choices'].is_a?(Array) ? parse_choice_chunk(data) : parse_answer_chunk(data)

          Chunk.new(
            role: :assistant,
            conversation_id: data['conversation_id'],
            tool_calls: nil,
            thinking_tokens: Chat.extract_thinking_tokens(data),
            **attributes
          )
        end

        def parse_choice_chunk(data)
          delta = data.dig('choices', 0, 'delta') || {}
          usage = data['usage'] || {}

          {
            model: data['model'],
            content: delta['content'],
            thinking: Thinking.build(
              text: delta['reasoning_content'] || delta['reasoning'] || delta['thinking'],
              signature: delta['reasoning_signature'] || delta['signature']
            ),
            input_tokens: usage['prompt_tokens'] || data.dig('metadata', 'usage', 'prompt_tokens'),
            output_tokens: usage['completion_tokens'] || data.dig('metadata', 'usage', 'completion_tokens')
          }
        end

        def parse_answer_chunk(data)
          {
            model: nil,
            content: data['answer'],
            thinking: Thinking.build(
              text: Chat.extract_thinking_text(data),
              signature: Chat.extract_thinking_signature(data)
            ),
            input_tokens: data.dig('metadata', 'usage', 'prompt_tokens') || data.dig('usage', 'prompt_tokens'),
            output_tokens: data.dig('metadata', 'usage', 'completion_tokens') || data.dig('usage', 'completion_tokens')
          }
        end
      end
    end
  end
end
