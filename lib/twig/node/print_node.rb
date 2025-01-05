module Twig
  module Node
    class PrintNode < Node
      def initialize(expr, lineno)
        super({ expr: }, {}, lineno)
      end

      def compile(compiler)
        compiler.
          write('yield ').
          subcompile(node(:expr)).
          raw("\n")
      end
    end
  end
end
