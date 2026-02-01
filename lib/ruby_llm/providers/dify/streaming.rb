# frozen_string_literal: true

module RubyLLM
  module Providers
    class Dify
      # Streaming methods of the OpenAI API integration
      module Streaming
        module_function

        def stream_url
          completion_url
        end

        def build_chunk(data)
          if data['choices'].is_a?(Array)
            delta = data.dig('choices', 0, 'delta') || {}
            usage = data['usage'] || {}
            content = delta['content']
            thinking_text = delta['reasoning_content'] || delta['reasoning'] || delta['thinking']
            thinking_signature = delta['reasoning_signature'] || delta['signature']
            thinking_tokens = Chat.extract_thinking_tokens(data)
            input_tokens = usage['prompt_tokens'] || data.dig('metadata', 'usage', 'prompt_tokens')
            output_tokens = usage['completion_tokens'] || data.dig('metadata', 'usage', 'completion_tokens')
            model_id = data['model']
          else
            content = data['answer']
            thinking_text = Chat.extract_thinking_text(data)
            thinking_signature = Chat.extract_thinking_signature(data)
            thinking_tokens = Chat.extract_thinking_tokens(data)
            input_tokens = data.dig('metadata', 'usage', 'prompt_tokens') || data.dig('usage', 'prompt_tokens')
            output_tokens = data.dig('metadata', 'usage', 'completion_tokens') || data.dig('usage', 'completion_tokens')
            model_id = nil
          end

          Chunk.new(
            role: :assistant,
            conversation_id: data['conversation_id'],
            model_id: model_id,
            content: content,
            thinking: Thinking.build(text: thinking_text, signature: thinking_signature),
            tool_calls: nil,
            input_tokens: input_tokens,
            output_tokens: output_tokens,
            thinking_tokens: thinking_tokens
          )
        end
      end
    end
  end
end
