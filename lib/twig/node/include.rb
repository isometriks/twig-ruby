# frozen_string_literal: true

module Twig
  module Node
    class Include < Node::Base
      include Output

      # @param [Expression::Base] expr
      # @param [Expression::Base, nil] variables
      # @param [Boolean] only
      # @param [Boolean] ignore_missing
      # @param [Integer] lineno
      def initialize(expr, variables, only, ignore_missing, lineno)
        nodes = { expr: }
        nodes[:variables] = variables if variables

        super(nodes, {
          only:,
          ignore_missing:,
        }, lineno)
      end

      def compile(compiler)
        compiler.add_debug_info(self)

        if attributes[:ignore_missing]
          template = compiler.var_name

          compiler.
            write("begin\n").
            indent.
            write("#{template} = ")

          add_get_template(compiler, template)

          compiler.
            raw("\n").
            outdent.
            write("rescue ::Twig::Error::Loader => e\n").
            indent.
            write("# ignore missing template\n").
            write("#{template} = nil\n").
            outdent.
            write("end\n").
            write("if #{template}\n").
            indent.
            write("#{template}.call(")

          add_template_arguments(compiler)

          compiler.
            raw(");\n").
            outdent.
            write("end\n")
        else
          compiler.
            write('')

          add_get_template(compiler)

          compiler.
            raw('.call(')

          add_template_arguments(compiler)

          compiler.
            raw(");\n")
        end
      end

      private

      # @param [Compiler] compiler
      def add_get_template(compiler, template = '')
        compiler.
          raw('load(').
          subcompile(nodes[:expr]).
          raw(', ').
          repr(lineno).
          raw(')')
      end

      # @param [Compiler] compiler
      def add_template_arguments(compiler)
        if !nodes.key?(:variables)
          compiler.raw(attributes[:only] == false ? 'context' : 'context.only({})')
        elsif attributes[:only] == false
          compiler.
            raw('context.merge(').
            subcompile(nodes[:variables]).
            raw(')')
        else
          compiler.
            raw('context.only(').
            subcompile(nodes[:variables]).
            raw(')')
        end
      end
    end
  end
end
