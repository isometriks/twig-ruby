# frozen_string_literal: true

module Twig
  module NodeVisitor
    # This visitor checks the contents of the Spread operator to see if it's a hash or array.
    # If it is, it converts it to a HashSpread or ArraySpread node.
    #
    # The cases where this is not, would be some kind of variable expression which we cannot determine
    # at compile time, and still need to be sent through the ArgumentSpreader so that they can be spread
    # properly into the destination callable.
    class Spreader < Base
      def enter_node(node, env)
        node
      end

      def leave_node(node, env)
        unless node.is_a?(Node::Expression::Unary::Spread)
          return node
        end

        if node.nodes[:node].instance_of?(Node::Expression::Hash)
          return Node::Expression::Unary::HashSpread.new(
            node.nodes[:node],
            node.lineno
          )
        end

        if node.nodes[:node].instance_of?(Node::Expression::Array)
          return Node::Expression::Unary::ArraySpread.new(
            node.nodes[:node],
            node.lineno
          )
        end

        node
      end
    end
  end
end
