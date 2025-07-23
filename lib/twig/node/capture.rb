# frozen_string_literal: true

module Twig
  module Node
    class Capture < Node::Base
      # @param [Node::Base] body
      # @param [Integer] lineno
      def initialize(body, lineno)
        super({ body: }, { raw: false }, lineno)
      end

      def compile(compiler)
        compiler.
          raw("context.buffer_and_return do\n").
          indent.
          subcompile(nodes[:body]).
          outdent.
          write("end.to_s.html_safe\n")
      end
    end
  end
end
