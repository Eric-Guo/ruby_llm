# frozen_string_literal: true

module RubyLLM
  module Providers
    class Dify
      # Media handling methods for the Dify API integration
      module Media
        module_function

        def format_files(attachments)
          return nil if attachments.empty?

          parts = []

          attachments.each do |attachment|
            raise UnsupportedAttachmentError, attachment.class unless attachment.provider_file?

            parts << format_provider_file(attachment)
          end

          parts
        end

        def format_provider_file(attachment)
          {
            type: dify_file_type(attachment),
            transfer_method: 'local_file',
            upload_file_id: attachment.provider_file_id
          }
        end

        def dify_file_type(attachment)
          return 'image' if attachment.image?
          return 'video' if attachment.video?
          return 'audio' if attachment.audio?
          return 'document' if attachment.pdf? || attachment.document? || attachment.text?

          'custom'
        end
      end
    end
  end
end
