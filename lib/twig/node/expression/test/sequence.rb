# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a variable is a sequence (array)
        #
        #  {{ var is a sequence }}
        class Sequence < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(').is_a?(Array)')
          end
        end
      end
    end
  end
end
