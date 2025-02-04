# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a variable is null.
        #
        #  {{ var is null }}
        class Null < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(' == nil)')
          end
        end
      end
    end
  end
end
