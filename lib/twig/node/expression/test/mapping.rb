# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Test
        # Checks if a variable is a mapping (Hash)
        #
        #  {{ var is a mapping }}
        class Mapping < Test::Base
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:node]).
              raw(').is_a?(Hash)')
          end
        end
      end
    end
  end
end
