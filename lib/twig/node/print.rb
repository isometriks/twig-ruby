# frozen_string_literal: true

module Twig
  module Node
    class Print < Node::Base
      def initialize(expr, lineno)
        super({ expr: }, {}, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          write('context.output_buffer.append = ').
          subcompile(nodes[:expr]).
          raw(";\n")
      end
    end
  end
end
