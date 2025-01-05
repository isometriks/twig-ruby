module Twig
  module Node
    class Nodes < Node
      # @param [Hash<Node>] nodes
      # @param [Integer] lineno
      def initialize(nodes, lineno = 0)
        super(nodes, {}, lineno)
      end
    end
  end
end
