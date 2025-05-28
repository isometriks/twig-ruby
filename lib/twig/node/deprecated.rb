# frozen_string_literal: true

module Twig
  module Node
    class Deprecated < Base
      def initialize(expr, lineno)
        super({ expr: }, {}, lineno)
      end

      def compile(compiler)
        compiler.add_debug_info(self)

        expr = nodes[:expr]

        unless expr.is_a?(Expression::Constant)
          var_name = compiler.var_name
          compiler.
            write("#{var_name} = ").
            subcompile(expr).
            raw("\n")
        end

        compiler.write('::Twig::Extension::Core.deprecation_notice(')

        if expr.is_a?(Expression::Constant)
          compiler.subcompile(expr)
        else
          compiler.write(var_name)
        end

        compiler.
          raw(', ').
          repr(template_name).
          raw(', ').
          repr(lineno)

        if (package = nodes.fetch(:package, nil))
          compiler.
            raw(', package: ').
            subcompile(package)
        end

        if (version = nodes.fetch(:version, nil))
          compiler.
            raw(', version: ').
            subcompile(version)
        end

        compiler.raw(")\n")
      end
    end
  end
end
