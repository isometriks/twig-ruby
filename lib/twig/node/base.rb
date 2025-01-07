module Twig
  module Node
    class Base
      attr_reader :tag, :attributes, :lineno

      # @return [Source]
      attr_reader :source_context

      # @return [Hash<Node::Base>]
      attr_reader :nodes

      # @param [Hash<Node::Base>] nodes
      # @param [Hash] attributes
      # @param [Integer] lineno
      def initialize(nodes = {}, attributes = {}, lineno = 0)
        invalid = nodes.
          values.
          detect { |node| !node.class.ancestors.include?(Node::Base) }

        raise "#{invalid.inspect} does not extend from #{Node::Base.name}" if invalid

        @nodes = nodes
        @attributes = attributes
        @lineno = lineno
        @tag = nil
      end

      # @param [String] tag
      def tag=(tag)
        raise 'Cannot only set node tag once' if @tag

        @tag = tag
      end

      # @param [Compiler] compiler
      def compile(compiler)
        @nodes.values.each { |node| compiler.subcompile(node) }
      end

      # @param [Source] source
      def source_context=(source)
        @source_context = source
        @nodes.values.each { |node| node.source_context = source }
      end
    end
  end
end
