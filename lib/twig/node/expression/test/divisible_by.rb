# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a number is divisible by another.
        #
        #  {{ var is divisible by(3) }}
        class DivisibleBy < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(' % ').
              subcompile(nodes[:arguments].nodes[0]).
              raw(' == 0)')
          end
        end
      end
    end
  end
end
