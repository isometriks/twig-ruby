# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        # The .. operator, which builds the same sequence as the range
        # function, as Twig's RangeBinary compiles to PHP's range()
        class Range < Binary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Extension::Core.range(').
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
