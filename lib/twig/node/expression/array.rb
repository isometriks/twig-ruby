# frozen_string_literal: true

require_relative 'support_defined_test'

module Twig
  module Node
    module Expression
      class Array < Expression::Base
        include Expression::SupportDefinedTest

        # @param [AutoHash] elements
        # @param [Integer] lineno
        def initialize(elements, lineno)
          super(elements, {}, lineno)
        end

        # @param [Expression::Base] value
        def add_element(value)
          nodes.add(value)
        end

        def compile(compiler)
          if define_test_enabled?
            return compiler.repr(true)
          end

          # Empty expressions are only valid in destructuring contexts
          values.each do |value|
            if value.is_a?(Expression::EmptySlot)
              raise Error::Syntax.new('Empty array elements are only allowed in destructuring assignments.',
                value.lineno)
            end
          end

          spreads = values.any? { |value| value.is_a?(Unary::ArraySpread) }

          # A spread is added at runtime, which keeps its string keys as PHP
          # does
          compiler.
            raw(spreads ? '::Twig::Runtime::Spread.sequence(' : '[').
            indent

          values.each_with_index do |value, index|
            compiler.raw(', ') if index.positive?

            if value.is_a?(Unary::ArraySpread)
              compiler.
                raw('::Twig::Runtime::Spread.new(').
                subcompile(value.nodes[:node]).
                raw(')')
            else
              compiler.subcompile(value)
            end
          end

          compiler.
            outdent.
            raw(spreads ? ')' : ']')
        end

        def values
          nodes.values
        end

        def each_value(&)
          values.each(&)
        end
      end
    end
  end
end
