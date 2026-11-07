# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Boolean < Binary::Base
          def compile(compiler)
            compiler.
              raw('(::Twig::Runtime::Truthiness.true?(').
              subcompile(nodes[:left]).
              raw(') ')

            operator(compiler)

            compiler.raw(' ::Twig::Runtime::Truthiness.true?(').
              subcompile(nodes[:right]).
              raw('))')
          end
        end
      end
    end
  end
end
