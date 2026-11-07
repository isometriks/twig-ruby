# frozen_string_literal: true

module Twig
  module Node
    module Expression
      module Unary
        class Base < Expression::Base
          # @param [Node::Base] node
          # @param [Integer] lineno
          def initialize(node, lineno)
            super({ node: }, { with_parenthesis: false }, lineno)
          end

          def compile(compiler)
            if explicit_parentheses?
              compiler.raw('(')
            else
              compiler.raw(' ')
            end

            operator(compiler)
            compiler.subcompile(nodes[:node])

            if explicit_parentheses?
              compiler.raw(')')
            end
          end

          # @param [Compiler] compiler
          def operator(compiler)
            raise 'operator is not implemented'
          end
        end

        OPERATORS = {
          Spread: '(not rendered)',
          ArraySpread: '*',
          HashSpread: '**',
        }.freeze

        # Lots of simple operator classes can just be generated dynamically
        OPERATORS.each do |name, operation|
          const_set(name.to_s, Class.new(Unary::Base) do
            def operator(compiler)
              compiler.raw(self.class.const_get('OPERATOR'))
            end
          end).const_set('OPERATOR', operation)
        end

        # PHP's -a and +a multiply a by -1 and 1, so a numeric string or null
        # is cast as in any arithmetic. A number written in the template is
        # just signed.
        { Neg: ['-', -1], Pos: ['+', 1] }.each do |name, (operation, factor)|
          const_set(name.to_s, Class.new(Unary::Base) do
            def compile(compiler)
              node = nodes[:node]
              return super if node.is_a?(Constant) && node.attributes[:value].is_a?(Numeric)

              compiler.
                raw('::Twig::Runtime::Arithmetic.multiply(').
                subcompile(node).
                raw(", #{self.class.const_get('FACTOR')})")
            end

            def operator(compiler)
              compiler.raw(self.class.const_get('OPERATOR'))
            end
          end).const_set('OPERATOR', operation).then { const_get(name).const_set('FACTOR', factor) }
        end
      end
    end
  end
end
