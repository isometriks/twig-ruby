# frozen_string_literal: true

module Twig
  module Node
    class Text < Node::Base
      include Output

      BOM = "\xEF\xBB\xBF".b

      # @param [String] data
      # @param [Integer] lineno
      def initialize(data, lineno = 0)
        super({}, { data: }, lineno)
      end

      # Whether the text only contains whitespace, possibly after a BOM
      #
      # @return [Boolean]
      def blank?
        data = attributes[:data].b

        return true if data.match?(/\A\s+\z/)

        data.start_with?(BOM) && data.delete_prefix(BOM).match?(/\A\s*\z/)
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
