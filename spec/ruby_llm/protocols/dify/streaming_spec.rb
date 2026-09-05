# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Protocols::Dify::Streaming do
  describe '.build_chunk' do
    it 'preserves Dify conversation, reasoning, and metadata usage' do
      chunk = described_class.build_chunk(
        'answer' => 'Hello',
        'conversation_id' => 'conversation-123',
        'metadata' => {
          'reasoning' => 'Let me think',
          'signature' => 'signature-123',
          'usage' => { 'prompt_tokens' => 3, 'completion_tokens' => 2 }
        },
        'usage' => { 'prompt_tokens' => 30, 'completion_tokens' => 20, 'thinking_tokens' => 4 }
      )

      expect(chunk.role).to eq(:assistant)
      expect(chunk.content).to eq('Hello')
      expect(chunk.conversation_id).to eq('conversation-123')
      expect(chunk.thinking.text).to eq('Let me think')
      expect(chunk.thinking.signature).to eq('signature-123')
      expect(chunk.tokens.input).to eq(3)
      expect(chunk.tokens.output).to eq(2)
      expect(chunk.tokens.thinking).to eq(4)
    end

    it 'preserves choice deltas and prefers their top-level usage' do
      chunk = described_class.build_chunk(
        'choices' => [{
          'delta' => {
            'content' => 'Hello',
            'reasoning_content' => 'Let me think',
            'reasoning_signature' => 'signature-123'
          }
        }],
        'conversation_id' => 'conversation-123',
        'usage' => {
          'prompt_tokens' => 3,
          'completion_tokens' => 2,
          'completion_tokens_details' => { 'reasoning_tokens' => 4 }
        },
        'metadata' => { 'usage' => { 'prompt_tokens' => 30, 'completion_tokens' => 20 } }
      )

      expect(chunk.role).to eq(:assistant)
      expect(chunk.content).to eq('Hello')
      expect(chunk.conversation_id).to eq('conversation-123')
      expect(chunk.thinking.text).to eq('Let me think')
      expect(chunk.thinking.signature).to eq('signature-123')
      expect(chunk.tokens.input).to eq(3)
      expect(chunk.tokens.output).to eq(2)
      expect(chunk.tokens.thinking).to eq(4)
    end
  end
end
