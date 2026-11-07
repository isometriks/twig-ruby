# frozen_string_literal: true

module Twig
  module Node
    # Twig's flush tag flushes PHP's output buffer. A template here renders
    # into a buffer its caller reads at the end, so there is nothing to
    # flush, and the node compiles to a comment where Twig calls flush().
    class Flush < Node::Base
      # @param [Integer] lineno
      def initialize(lineno)
        super({}, {}, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          write("# flush\n")
      end
    end
  end
end
