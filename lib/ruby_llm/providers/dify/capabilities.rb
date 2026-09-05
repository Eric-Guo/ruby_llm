# frozen_string_literal: true

module RubyLLM
  module Providers
    class Dify
      module Capabilities # :nodoc:
        module_function

        def capabilities_for(_model_id)
          ['streaming']
        end
      end
    end
  end
end
