# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a variable is the same as another.
        #
        #  {{ var is same as(other) }}
        class SameAs < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(' == ').
              subcompile(nodes[:arguments].nodes[0]).
              raw(')')
          end
        end
      end
    end
  end
end
