# frozen_string_literal: true

module Twig
  module Node
    # Declares the expected types of context variables, for tooling. It
    # compiles to nothing.
    class Types < Node::Base
      # @param [Hash{String => Hash}] types name => { type:, optional: }
      # @param [Hash{String => Node::Type}] nodes
      # @param [Integer] lineno
      def initialize(types, nodes, lineno)
        super(nodes, { mapping: types }, lineno)
      end

      def compile(compiler); end
    end
  end
end
