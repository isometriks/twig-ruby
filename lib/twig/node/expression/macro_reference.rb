# frozen_string_literal: true

module Twig
  module Node
    module Expression
      # Represents a macro call node.
      class MacroReference < Expression::Base
        include SupportDefinedTest

        # @param [Variable::Template] template
        # @param [String] name
        # @param [Expression::Base] arguments
        # @param [Integer] lineno
        def initialize(template, name, arguments, lineno)
          super({ template:, arguments: }, { name: }, lineno)
        end

        # @param [Compiler] compiler
        def compile(compiler)
          if define_test_enabled?
            compiler.
              subcompile(nodes[:template]).
              raw('.macro?(').
              repr(attributes[:name]).
              raw(', context').
              raw(')')
            return
          end

          compiler.
            subcompile(nodes[:template]).
            raw('.render_macro(').
            repr(attributes[:name]).
            raw(', context, ').
            subcompile(nodes[:arguments]).
            raw(', ').
            repr(lineno).
            raw(', source_context)')
        end
      end
    end
  end
end
