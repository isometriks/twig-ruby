# frozen_string_literal: true

module Twig
  module Node
    class Capture < Node::Base
      # @param [Node::Base] body
      # @param [Integer] lineno
      def initialize(body, lineno)
        super({ body: }, { raw: false }, lineno)
      end

      # @todo raw is missing, but I think only used by cache node?
      def compile(compiler)
        # Swap output buffer with a temp one and then add it
        compiler.
          raw("(tmp = @output_buffer.class.new\n").
          write("@output_buffer, tmp = tmp, @output_buffer\n").
          subcompile(nodes[:body]).
          write("@output_buffer, tmp = tmp, @output_buffer\n").
          write("tmp.to_s.html_safe)\n")
      end
    end
  end
end
