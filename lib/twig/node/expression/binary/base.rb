module Twig
  module Node
    module Expression
      module Binary
        class Base < Expression::Base
          def initialize(left, right, lineno)
            super({ left:, right: }, {}, lineno)
          end

          # @param [Compiler] compiler
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(nodes[:left]).
              raw(' ')

            operator(compiler)

            compiler.
              raw(' ').
              subcompile(nodes[:right]).
              raw(')')
          end

          # @param [Compiler] compiler
          def operator(compiler)
            raise "operator is not implemented"
          end
        end

        OPERATORS = {
          Equal: '==',
          NotEqual: '!=',
          Spaceship: '<=>',
          Less: '<',
          Greater: '>',
          LessEqual: '<=',
          GreaterEqual: '>=',

          Or: '||',
          And: '&&',
          Add: '+',
          Sub: '-',
          Mul: '*',
          Div: '/',
        }

        # Lots of simple operator classes can just be generated dynamically
        OPERATORS.each do |name, operation|
          const_set("#{name}", Class.new(Binary::Base) do
            def operator(compiler)
              compiler.raw(self.class.const_get("OPERATOR"))
            end
          end).const_set("OPERATOR", operation)
        end
      end
    end
  end
end
