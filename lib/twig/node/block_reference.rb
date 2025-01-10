module Twig
  module Node
    class BlockReference < Node::Base
      def initialize(name, lineno)
        super({}, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          write("yield yield_block(:#{attributes[:name]}, context, block_list.merge(blocks))").
          raw("\n")
      end
    end
  end
end
