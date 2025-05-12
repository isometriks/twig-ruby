# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class HasEvery < Binary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Extension::Core.array_every?(').
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
