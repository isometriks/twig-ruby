module Twig
  module Node
    class Print < Node::Base
      def initialize(expr, lineno)
        super({ expr: }, {}, lineno)
      end

      def compile(compiler)
        compiler.
          write('yield ').
          subcompile(nodes[:expr]).
          raw("\n")
      end
    end
  end
end
