# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class FloorDiv < Binary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Runtime::Division.floor_divide(').
              subcompile(nodes[:left]).
              raw(', ').
              subcompile(nodes[:right]).
              raw(')')
          end
        end
      end
    end
  end
end
