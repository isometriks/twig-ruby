# frozen_string_literal: true

module Twig
  module Node
    class AutoEscape < Node::Base
      # @param [String, FalseClass] value
      # @param [Node::Base] body
      # @param [Integer] lineno
      def initialize(value, body, lineno)
        super({ body: }, { value: }, lineno)
      end

      def compile(compiler)
        compiler.subcompile(nodes[:body])
      end
    end
  end
end
