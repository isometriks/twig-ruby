# frozen_string_literal: true

module Twig
  module NodeVisitor
    class Base
      # Called before child nodes are visited.
      #
      # @param [Node::Base] node
      # @param [Environment] env
      # @return [Node::Base] The modified node
      def enter_node(node, env)
        raise NotImplementedError, "Method #{__method__} must be implemented"
      end

      # Called after child nodes are visited.
      #
      # @param [Node::Base] node
      # @param [Environment] env
      # @return [Node::Base, nil] The modified node or nil if the node must be removed
      def leave_node(node, env)
        raise NotImplementedError, "Method #{__method__} must be implemented"
      end

      # @return [Integer] The priority level
      def priority
        0
      end
    end
  end
end
