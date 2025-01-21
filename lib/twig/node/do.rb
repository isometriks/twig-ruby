# frozen_string_literal: true

module Twig
  module Node
    class Do < Node::Base
      # @param [Node::Expression::Base] expr
      # @param [Integer] lineno
      def initialize(expr, lineno)
        super({ expr: }, {}, lineno)
      end

      def compile(compiler)
        compiler.
          subcompile(nodes[:expr], raw: false).
          raw("\n")
      end
    end
  end
end
