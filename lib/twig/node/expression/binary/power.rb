# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Binary
        class Power < Binary::Base
          def compile(compiler)
            compile_power(compiler, nodes[:left])
          end

          private

          # Twig parses -2 ** 2 as (-2) ** 2 but compiles it to PHP's
          # -2 ** 2, where ** binds tighter than the sign, so it is -4. A
          # sign without parentheses is therefore applied to the power.
          def compile_power(compiler, base)
            if (base.is_a?(Unary::Neg) || base.is_a?(Unary::Pos)) && !base.explicit_parentheses?
              compiler.raw("(#{base.class::OPERATOR}")
              compile_power(compiler, base.nodes[:node])
              compiler.raw(')')

              return
            end

            compiler.
              raw('::Twig::Runtime::Exponentiation.power(').
              subcompile(base).
              raw(', ').
              subcompile(nodes[:right]).
              raw(')')
          end
        end
      end
    end
  end
end
