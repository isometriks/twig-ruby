# frozen_string_literal: true

module Twig
  module Node
    module Expression
      class HelperMethod < Call
        def initialize(name, arguments, lineno)
          super({ arguments: }, { name: }, lineno)
        end

        private

        def callable_method
          "context.call_context.method(:#{attributes[:name]})"
        end
      end
    end
  end
end
