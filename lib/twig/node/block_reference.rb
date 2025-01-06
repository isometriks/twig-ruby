module Twig
  module Node
    class BlockReference < Node
      def initialize(name, lineno)
        super({}, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          write("yield yield_block(:#{attributes[:name]})").
          raw("\n")
      end
    end
  end
end
