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
            # Through the % operator, which casts as PHP does
            compiler.
              raw('(::Twig::Runtime::Modulo.modulo(').
              subcompile(nodes[:node]).
              raw(', 2) == 0)')
          end
        end
      end
    end
  end
end
