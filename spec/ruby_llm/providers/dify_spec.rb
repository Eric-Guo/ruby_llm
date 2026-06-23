# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Dify do
  subject(:provider) { described_class.new(config) }

  let(:config) do
    instance_double(
      RubyLLM::Configuration,
      dify_api_base: 'https://dify.example.com',
      dify_api_key: 'test-key',
      dify_user: 'test-user',
      dify_protocol: nil,
      auto_upload_large_files: true
    )
  end
  let(:connection) { instance_double(RubyLLM::Connection) }
  let(:model) { instance_double(RubyLLM::Model, id: 'dify-chat') }
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
        ),
        usage: instance_of(RubyLLM::Usage::Tracker)
      )
      expect(result.content).to eq('您好')
      expect(result.conversation_id).to eq('conversation-123')
    end
  end

  describe '#upload_file' do
    it 'uploads through the official provider files API' do
      upload_response = instance_double(
        Faraday::Response,
        body: {
          'id' => 'dify-file-123',
          'name' => 'notes.txt',
          'size' => 12,
          'mime_type' => 'text/plain',
          'created_at' => 1_700_000_000
        }
      )
      allow(connection).to receive(:post).and_return(upload_response)

      file = provider.upload_file(StringIO.new('hello'), filename: 'notes.txt')

      expect(connection).to have_received(:post).with(
        'v1/files/upload',
        hash_including(:file, user: 'test-user')
      )
      expect(file).to be_a(RubyLLM::UploadedFile)
      expect(file.id).to eq('dify-file-123')
      expect(file.provider).to eq('dify')
      expect(file.filename).to eq('notes.txt')
      expect(file.byte_size).to eq(12)
      expect(file.mime_type).to eq('text/plain')
      expect(file.created_at).to eq(Time.at(1_700_000_000))
    end
  end

  describe '#render' do
    it 'formats provider-managed files as Dify local files' do
      file = RubyLLM::UploadedFile.new(
        id: 'dify-file-123',
        provider: 'dify',
        filename: 'notes.txt',
        mime_type: 'text/plain'
      )
      message = RubyLLM::Message.new(role: :user, content: 'Summarize this', attachments: [file])

      payload = provider.render(
        [message],
        tools: {},
        temperature: nil,
        model: model
      )

      expect(payload[:files]).to contain_exactly(
        {
          type: 'document',
          transfer_method: 'local_file',
          upload_file_id: 'dify-file-123'
        }
      )
    end

    it 'formats provider-managed image files with the Dify image type' do
      file = RubyLLM::UploadedFile.new(
        id: 'dify-image-123',
        provider: 'dify',
        filename: 'ruby.png',
        mime_type: 'image/png'
      )
      message = RubyLLM::Message.new(role: :user, content: 'Describe this', attachments: [file])

      payload = provider.render(
        [message],
        tools: {},
        temperature: nil,
        model: model
      )

      expect(payload[:files]).to contain_exactly(
        {
          type: 'image',
          transfer_method: 'local_file',
          upload_file_id: 'dify-image-123'
        }
      )
    end
  end

  describe '#preprocess_message' do
    it 'uploads attachable files into provider-managed references' do
      attachment = RubyLLM::Attachment.new(StringIO.new('hello'), filename: 'notes.txt')
      upload_response = instance_double(
        Faraday::Response,
        body: {
          'id' => 'dify-file-123',
          'name' => 'notes.txt',
          'mime_type' => 'text/plain'
        }
      )
      allow(connection).to receive(:post).and_return(upload_response)
      message = RubyLLM::Message.new(
        role: :user,
        content: 'Summarize this',
        attachments: [attachment]
      )

      processed = provider.preprocess_message(message, model: model)

      expect(processed).not_to be(message)
      expect(processed.attachments.first).to be_provider_file
      expect(processed.attachments.first.provider_file_id).to eq('dify-file-123')
      expect(connection).to have_received(:post).with(
        'v1/files/upload',
        hash_including(:file, user: 'test-user')
      )
    end
  end
end
