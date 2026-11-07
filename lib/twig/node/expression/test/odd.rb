# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a number is odd.
        #
        #  {{ var is odd }}
        class Odd < Test::Base
          def compile(compiler)
            # Through the % operator, which casts as PHP does
            compiler.
              raw('(::Twig::Runtime::Modulo.modulo(').
              subcompile(nodes[:node]).
              raw(', 2) != 0)')
          end
        end
      end
    end
  end
end
