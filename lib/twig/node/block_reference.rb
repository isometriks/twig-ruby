# frozen_string_literal: true

module Twig
  module Node
    class BlockReference < Node::Base
      def initialize(name, lineno)
        super({}, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          write('context.output_buffer.safe_append = ').
          raw("yield_block(:#{attributes[:name]}, context, self.blocks.merge(blocks))").
          raw("\n")
      end
    end
  end
end
