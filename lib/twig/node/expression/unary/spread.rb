# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Unary
        class Spread < Unary::Base
          def compile(compiler)
            compiler.
              raw('::Twig::Runtime::Spread.new(').
              subcompile(nodes[:node]).
              raw(')')
          end
        end
      end
    end
  end
end
