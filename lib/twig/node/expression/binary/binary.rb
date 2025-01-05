module Twig
  module Node
    module Expression
      module Binary
        class Binary < Expression
          def initialize(left, right, lineno)
            super({ left:, right: }, {}, lineno)
          end

          # @param [Compiler] compiler
          def compile(compiler)
            compiler.
              raw('(').
              subcompile(node(:left)).
              raw(' ')

            operator(compiler)

            compiler.
              raw(' ').
              subcompile(node(:right)).
              raw(')')
          end

          # @param [Compiler] compiler
          def operator(compiler)
            raise "operator is not implemented"
          end
        end

        OPERATORS = {
          Or: '||',
          And: '&&',
          Equal: '==',
          Add: '+',
          Sub: '-',
          Mul: '*',
          Div: '/',
        }

        # Lots of simple operator classes can just be generated dynamically
        OPERATORS.each do |name, operation|
          const_set("#{name}Binary", Class.new(Binary) do
            def operator(compiler)
              compiler.raw(self.class.const_get("OPERATOR"))
            end
          end).const_set("OPERATOR", operation)
        end
      end
    end
  end
end
