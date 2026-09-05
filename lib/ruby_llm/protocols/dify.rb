# frozen_string_literal: true

module RubyLLM
  module Protocols
    # The Dify chat API wire format.
    class Dify < Protocol
      include Dify::Chat
      include Dify::Media
      include Dify::Streaming
    end
  end
end
