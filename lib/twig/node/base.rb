# frozen_string_literal: true

require_relative 'output'

module Twig
  module Node
    class Base
      attr_reader :tag

      # @return [Integer]
      attr_reader :lineno

      # @return [Hash]
      attr_reader :attributes

      # @return [Source]
      attr_reader :source_context

      # @return [AutoHash{[Symbol, Integer] => Node::Base}]
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
        @nodes.each_value { |node| compiler.subcompile(node) }
      end

      # @param [Source] source
      def source_context=(source)
        @source_context = source
        @nodes.each_value { |node| node.source_context = source }
      end

      # @return [String]
      def template_name
        source_context.name
      end

      # @return [Integer]
      def length
        nodes.length
      end

      def empty?
        nodes.empty?
      end

      def to_s
        repr = +''
        repr << self.class.name

        if @tag
          repr << "\n tag: #{@tag}"
        end

        attr = attributes.map do |name, value|
          v = if value.is_a?(Proc) || value.is_a?(Method)
                '\Closure'
              elsif value.is_a?(String)
                value
              else
                value.inspect
              end

          "#{name}: #{v}"
        end

        unless attr.empty?
          repr << "\n  attributes:\n    #{attr.join("\n    ")}"
        end

        unless empty?
          repr << "\n  nodes:"

          nodes.each do |name, node|
            len = name.to_s.length + 6
            node_repr = []

            node.to_s.each_line do |line|
              node_repr << ((' ' * len) + line.rstrip)
            end

            repr << "\n    #{name}: #{node_repr.join("\n").lstrip}"
          end
        end

        repr
      end
    end
  end
end
