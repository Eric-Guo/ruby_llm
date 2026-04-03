# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Dify do
  subject(:provider) { described_class.new(config) }

  let(:config) do
    instance_double(
      RubyLLM::Configuration,
      dify_api_base: 'https://dify.example.com',
      dify_api_key: 'test-key',
      dify_user: 'test-user'
    )
  end
  let(:connection) { instance_double(RubyLLM::Connection) }
  let(:model) { instance_double(RubyLLM::Model::Info, id: 'dify-chat') }
  let(:messages) { [RubyLLM::Message.new(role: :user, content: '你好')] }
  let(:response) do
    instance_double(
      Faraday::Response,
      body: {
        'answer' => '您好',
        'conversation_id' => 'conversation-123',
        'metadata' => {
          'usage' => {
            'prompt_tokens' => 3,
            'completion_tokens' => 2
          }
        }
      }
    )
  end

  before do
    allow(RubyLLM::Connection).to receive(:new).and_return(connection)
    allow(connection).to receive(:post).and_return(response)
  end

  describe '#complete' do
    it 'accepts tool_prefs forwarded by the chat layer' do
      result = provider.complete(
        messages,
        tools: {},
        tool_prefs: { choice: :auto, calls: :many },
        temperature: nil,
        model: model
      )

      expect(connection).to have_received(:post).with(
        'v1/chat-messages',
        hash_including(
          query: '你好',
          response_mode: 'blocking',
          user: 'test-user'
        )
      )
      expect(result.content).to eq('您好')
      expect(result.conversation_id).to eq('conversation-123')
    end
  end
end
