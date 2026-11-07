# frozen_string_literal: true

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
            raise 'operator is not implemented'
          end
        end

        # Operators that compare or calculate as PHP does, through a runtime
        # method, instead of with Ruby's operators
        RUNTIME_OPERATORS = {
          Equal: 'Comparison.equal?',
          NotEqual: 'Comparison.not_equal?',
          Spaceship: 'Comparison.compare',
          Less: 'Comparison.less?',
          Greater: 'Comparison.greater?',
          LessEqual: 'Comparison.less_equal?',
          GreaterEqual: 'Comparison.greater_equal?',

          BitwiseOr: 'Arithmetic.bitwise_or',
          BitwiseXor: 'Arithmetic.bitwise_xor',
          BitwiseAnd: 'Arithmetic.bitwise_and',
          Add: 'Arithmetic.add',
          Sub: 'Arithmetic.subtract',
          Mul: 'Arithmetic.multiply',
        }.freeze

        RUNTIME_OPERATORS.each do |name, method|
          const_set(name.to_s, Class.new(Binary::Base) do
            def compile(compiler)
              compiler.
                raw("::Twig::Runtime::#{self.class.const_get('METHOD')}(").
                subcompile(nodes[:left]).
                raw(', ').
                subcompile(nodes[:right]).
                raw(')')
            end
          end).const_set('METHOD', method)
        end
      end
    end
  end
end
