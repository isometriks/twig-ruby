# frozen_string_literal: true

module Twig
  module Node
    class Deprecated < Base
      def initialize(expr, lineno)
        super({ expr: }, {}, lineno)
      end

      # Reports the deprecation as Twig's DeprecatedNode does, with
      # trigger_deprecation(package, version, '%s in "%s" at line %d.')
      def compile(compiler)
        compiler.
          add_debug_info(self).
          write('::Twig::Extension::Core.trigger_deprecation(')

        %i[package version].each do |name|
          if (node = nodes.fetch(name, nil))
            compiler.subcompile(node)
          else
            compiler.raw("''")
          end

          compiler.raw(', ')
        end

        compiler.
          raw('(').
          subcompile(nodes[:expr]).
          raw(').to_s + ').
          string(" in \"#{template_name}\" at line #{lineno}.").
          raw(")\n")
      end
    end
  end
end
