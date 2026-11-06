# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class SameAs < Binary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Runtime::Identity.same?(').
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
