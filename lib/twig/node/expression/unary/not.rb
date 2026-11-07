# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Unary
        class Not < Unary::Base
          def compile(compiler)
            compiler.
              raw('!::Twig::Runtime::Truthiness.true?(').
              subcompile(nodes[:node]).
              raw(')')
          end
        end
      end
    end
  end
end
