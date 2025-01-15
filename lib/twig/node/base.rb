# frozen_string_literal: true

module Twig
  module Node
    class Base
      attr_reader :tag, :lineno

      # @return [Hash]
      attr_reader :attributes

      # @return [Source]
      attr_reader :source_context

      # @return [AutoHash<Node::Base>]
      attr_reader :nodes

      # @param [Hash<Node::Base>] nodes
      # @param [Hash] attributes
      # @param [Integer] lineno
      def initialize(nodes = {}, attributes = {}, lineno = 0)
        invalid = nodes.
          values.
          detect { |node| !node.class.ancestors.include?(Node::Base) }

        raise "#{invalid.inspect} does not extend from #{Node::Base.name}" if invalid

        @nodes = AutoHash[nodes]
        @nodes.default_proc = ->(_hash, key) { raise "Node '#{key}' does not exist" }

        @attributes = attributes
        @attributes.default_proc = ->(_hash, key) { raise "Attribute '#{key}' does not exist" }

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

      # @return [String]
      def template_name
        source_context.name
      end
    end
  end
end
