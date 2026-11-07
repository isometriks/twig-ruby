# frozen_string_literal: true

module Twig
  module Node
    module Expression
      # Represents a macro call node.
      class MacroReference < Expression::Base
        include SupportDefinedTest

        # @param [Variable::Macro] template
        # @param [String, Expression::Base] name The bare macro name or, for a dynamic call, an
        #   expression that gives it
        # @param [Expression::Base] arguments
        # @param [Integer] lineno
        def initialize(template, name, arguments, lineno)
          if name.is_a?(String)
            super({ template:, arguments: }, { name:, has_call_parentheses: true }, lineno)
          else
            super({ template:, arguments:, name: }, { name: nil, has_call_parentheses: true }, lineno)
          end
        end

        # Whether the macro name was followed by parentheses, as in macros.hello()
        def call_parentheses?
          attributes[:has_call_parentheses]
        end

        # @param [Boolean] value
        def call_parentheses=(value)
          attributes[:has_call_parentheses] = value
        end

        # @param [Compiler] compiler
        def compile(compiler)
          compiler.subcompile(nodes[:template])

          if define_test_enabled?
            compiler.
              raw('.has?(')

            compile_name(compiler)

            compiler.raw(', context)')
            return
          end

          compiler.raw('.call(')
          compile_name(compiler)
          compiler.raw(', ')

          compile_arguments(compiler)

          compiler.
            raw(', context, ').
            repr(lineno).
            raw(', source_context)')
        end

        private

        # A dynamic name is converted to a string at runtime, as PHP's (string) cast does
        #
        # @param [Compiler] compiler
        def compile_name(compiler)
          if nodes.key?(:name)
            compiler.
              raw('(').
              subcompile(nodes[:name]).
              raw(').to_s')
          else
            compiler.repr(attributes[:name])
          end
        end

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
