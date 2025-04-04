# frozen_string_literal: true

module Twig
  module Node
    class Include < Node::Base
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
        if attributes[:ignore_missing]
          template = compiler.var_name

          compiler.
            write("begin\n").
            indent.
            write("#{template} = ")

          add_get_template(compiler)

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
      def add_get_template(compiler)
        compiler.
          raw('load_template(').
          subcompile(nodes[:expr]).
          raw(', ').
          repr(template_name).
          raw(', ').
          repr(lineno).
          raw(')')
      end

      # @param [Compiler] compiler
      def add_template_arguments(compiler)
        if !nodes.key?(:variables)
          compiler.raw(attributes[:only] == false ? 'context' : '{}')
        elsif attributes[:only] == false
          compiler.
            raw('context.merge(').
            subcompile(nodes[:variables]).
            raw(')')
        else
          compiler.
            subcompile(nodes[:variables])
        end
      end
    end
  end
end
