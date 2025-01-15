# frozen_string_literal: true

module Twig
  module Node
    class Nodes < Node::Base
      # @param [Hash<Node::Base>] nodes
      # @param [Integer] lineno
      def initialize(nodes, lineno = 0)
        super(nodes, {}, lineno)
      end
    end
  end
end
