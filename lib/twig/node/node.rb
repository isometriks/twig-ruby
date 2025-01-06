module Twig
  module Node
    class Node
      attr_reader :tag, :attributes

      # @param [Hash<Node::Node>] nodes
      # @param [Hash] attributes
      # @param [Integer] lineno
      def initialize(nodes = {}, attributes = {}, lineno = 0)
        invalid = nodes.
          values.
          detect { |node| !node.class.ancestors.include?(Node) }

        raise "#{invalid.inspect} does not extend from #{Node.name}" if invalid

        @nodes = nodes
        @attributes = attributes
        @lineno = lineno
        @tag = nil
      end

      def node(name)
        @nodes[name]
      end

      # @param [String] tag
      def tag=(tag)
        raise 'Cannot only set node tag once' if @tag.present?

        @tag = tag
      end

      # @param [Compiler] compiler
      def compile(compiler)
        @nodes.values.each { |node| compiler.subcompile(node) }
      end
    end
  end
end
