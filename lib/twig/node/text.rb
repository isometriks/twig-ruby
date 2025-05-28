# frozen_string_literal: true

module Twig
  module Node
    class Text < Node::Base
      # @param [String] data
      # @param [Integer] lineno
      def initialize(data, lineno = 0)
        super({}, { data: }, lineno)
      end

      def compile(compiler)
        compiler.
          add_debug_info(self).
          write('context.output_buffer.safe_append = ').
          string(attributes[:data]).
          raw(";\n")
      end
    end
  end
end
