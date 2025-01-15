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
          Not: '!',
          Neg: '-',
          Pos: '+',
        }

        # Lots of simple operator classes can just be generated dynamically
        OPERATORS.each do |name, operation|
          const_set("#{name}", Class.new(Unary::Base) do
            def operator(compiler)
              compiler.raw(self.class.const_get('OPERATOR'))
            end
          end).const_set('OPERATOR', operation)
        end
      end
    end
  end
end
