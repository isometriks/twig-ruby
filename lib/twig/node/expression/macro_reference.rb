# frozen_string_literal: true

module Twig
  module Node
    module Expression
      # Represents a macro call node.
      class MacroReference < Expression::Base
        include SupportDefinedTest

        # @param [Variable::Template] template
        # @param [String] name The bare macro name
        # @param [Expression::Base] arguments
        # @param [Integer] lineno
        def initialize(template, name, arguments, lineno)
          super({ template:, arguments: }, { name: }, lineno)
        end

        # @param [Compiler] compiler
        def compile(compiler)
          compiler.subcompile(nodes[:template])

          if define_test_enabled?
            compiler.
              raw('.has?(').
              repr(attributes[:name]).
              raw(', context)')
            return
          end

          compiler.
            raw('.call(').
            repr(attributes[:name]).
            raw(', ')

          compile_arguments(compiler)

          compiler.
            raw(', context, ').
            repr(lineno).
            raw(', source_context)')
        end

        private

        # Positional arguments are keyed by position and named ones by name. A spread is
        # kept whole, for the macro to expand at runtime.
        #
        # @param [Compiler] compiler
        def compile_arguments(compiler)
          arguments = nodes[:arguments]

          unless arguments.is_a?(Expression::Hash)
            # Called without parentheses
            compiler.raw('{}')
            return
          end

          compiler.raw('{')

          arguments.key_value_pairs.each_with_index do |(key, value), index|
            compiler.
              raw(index.zero? ? '' : ', ').
              subcompile(key).
              raw(' => ')

            if value.is_a?(Unary::Spread) || value.is_a?(Unary::ArraySpread) || value.is_a?(Unary::HashSpread)
              compiler.
                raw('::Twig::Runtime::Spread.new(').
                subcompile(value.nodes[:node]).
                raw(')')
            else
              compiler.subcompile(value)
            end
          end

          compiler.raw('}')
        end
      end
    end
  end
end
