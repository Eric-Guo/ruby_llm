# frozen_string_literal: true

module RubyLLM
  module Providers
    class Dify
      # Dify Files API.
      class Files < UploadedFile::Protocol
        private

        def files_url
          'v1/files/upload'
        end

        def render_upload_payload(attachment, user: nil, **)
          multipart_payload(attachment, user: user || @config.dify_user || 'dify-user')
        end

        def parse_file_response(data)
          uploaded_file(
            data,
            id: field(data, 'id'),
            filename: field(data, 'name') || field(data, 'filename'),
            byte_size: field(data, 'size') || field(data, 'bytes'),
            created_at: timestamp(field(data, 'created_at')),
            mime_type: field(data, 'mime_type')
          )
        end

        def field(data, key)
          data[key] || data[key.to_sym]
        end
      end
    end
  end
end
