# frozen_string_literal: true

module Twig
  module Node
    class BlockReference < Node::Base
      include Output

      def initialize(name, lineno)
        super({}, { name: }, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          write('context.output_buffer.safe_append = ').
          raw("render_block(:#{attributes[:name]}, context, blocks)").
          raw("\n")
      end
    end
  end
end
