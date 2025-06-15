# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Matches < Binary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Extension::Core.matches(').
              subcompile(nodes[:right]).
              raw(', ').
              subcompile(nodes[:left]).
              raw(')')
          end

          def operator(compiler)
            compiler.raw('')
          end
        end
      end
    end
  end
end
