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

        OPERATORS = {
          BitwiseOr: '|',
          BitwiseXor: '^',
          BitwiseAnd: '&',

          Add: '+',
          Sub: '-',
          Mul: '*',
        }.freeze

        # Lots of simple operator classes can just be generated dynamically
        OPERATORS.each do |name, operation|
          const_set(name.to_s, Class.new(Binary::Base) do
            def operator(compiler)
              compiler.raw(self.class.const_get('OPERATOR'))
            end
          end).const_set('OPERATOR', operation)
        end

        # The comparison operators compare values as PHP does, through
        # Runtime::Comparison, instead of with Ruby's operators
        COMPARISONS = {
          Equal: :equal?,
          NotEqual: :not_equal?,
          Spaceship: :compare,
          Less: :less?,
          Greater: :greater?,
          LessEqual: :less_equal?,
          GreaterEqual: :greater_equal?,
        }.freeze

        COMPARISONS.each do |name, method|
          const_set(name.to_s, Class.new(Binary::Base) do
            def compile(compiler)
              compiler.
                raw("::Twig::Runtime::Comparison.#{self.class.const_get('METHOD')}(").
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
