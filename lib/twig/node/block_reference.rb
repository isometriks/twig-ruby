# frozen_string_literal: true

module Twig
  module Node
    class BlockReference < Node::Base
      def initialize(name, lineno)
        super({}, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          write("yield_block(:#{attributes[:name]}, context, self.blocks.merge(blocks));").
          raw("\n")
      end
    end
  end
end
