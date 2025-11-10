# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Attachment do
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
