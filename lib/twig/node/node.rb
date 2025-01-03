module Twig
  module Node
    class Node
      attr_reader :tag, :attributes

      # @param [Array<Node::Node>] nodes
      # @param [Hash] attributes
      # @param [Integer] lineno
      def initialize(nodes = [], attributes = {}, lineno = 0)
        nodes.
          detect { |node| !node.class.ancestors.include?(self.class) }
          &.then { |node| raise "#{node.inspect} does not extend from #{self.class.name}"}

        @nodes = nodes
        @attributes = attributes
        @lineno = lineno
        @tag = nil
      end

      # @param [String] tag
      def tag=(tag)
        raise 'Cannot only set node tag once' if @tag.present?

        @tag = tag
      end
    end
  end
end
