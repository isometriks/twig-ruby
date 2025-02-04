# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a number is even.
        #
        #  {{ var is even }}
        class Even < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(' % 2 == 0)')
          end
        end
      end
    end
  end
end
