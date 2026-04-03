# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'

RSpec.describe RubyLLM::Attachment do
  it 'supports path attachments from the public API' do
    script = <<~'RUBY'
      require 'ruby_llm'

      content = RubyLLM::Content.new('What is in this file?', 'spec/fixtures/ruby.txt')
      attachment = content.attachments.first
      puts "#{attachment.filename},#{attachment.mime_type}"
    RUBY

    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby, '-Ilib', '-e', script,
      chdir: File.expand_path('../..', __dir__)
    )

    expect(status.success?).to be(true), stderr
    expect(stdout.strip).to eq('ruby.txt,text/plain')
  end

  describe 'file id sources' do
    it 'treats UUID strings as upload file ids' do
      file_id = '123e4567-e89b-12d3-a456-426614174000'

      attachment = described_class.new(file_id)

      expect(attachment.upload_file_id).to eq(file_id)
      expect(attachment.type).to eq(:file_id)
      expect(attachment.filename).to eq('attachment')
      expect(attachment.path?).to be(false)
    end
  end
end
