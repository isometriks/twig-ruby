# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Unary
        class StringCast < Unary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Runtime::StringCast.cast(').
              subcompile(nodes[:node]).
              raw(')')
          end
        end
      end
    end
  end
end
