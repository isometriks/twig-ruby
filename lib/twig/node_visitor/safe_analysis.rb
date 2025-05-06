# frozen_string_literal: true

module Twig
  module NodeVisitor
    class SafeAnalysis < Base
      SAFE_ALL = [
        Node::Expression::Constant,
        Node::Expression::BlockReference,
        Node::Expression::Parent,
        Node::Expression::MacroReference,
        Node::Expression::HelperMethod,
      ].freeze

      def initialize
        super

        @data = {}
        @safe_vars = []
      end

      def enter_node(node, env)
        node
      end

      def leave_node(node, env)
        if SAFE_ALL.any? { |klass| node.is_a?(klass) }
          set_safe(node, [:all])
        elsif node.is_a?(Node::Expression::OperatorEscape)
          operands = node.operand_names_to_escape

          if operands.length > 2
            raise ArgumentError, "Operators with more than 2 operands are not supported yet, got #{operands.length}."
          elsif operands.length == 2
            safe = intersect_safe(safe(node.nodes[operands[0]]), safe(node.nodes[operands[1]]))
            set_safe(node, safe)
          end
        elsif node.is_a?(Node::Expression::Filter)
          # Filter expression is safe when the filter is safe
          if node.attributes.key?(:twig_callable) && (filter = node.attributes[:twig_callable])
            unless (safe = filter.safe(node.nodes[:arguments]))
              safe = intersect_safe(safe(node.nodes[:node]), filter.preserves_safety)
            end

            set_safe(node, safe)
          end
        elsif node.is_a?(Node::Expression::Function)
          # Function expression is safe when the function is safe
          if node.attributes.key?(:twig_callable) && (function = node.attributes[:twig_callable])
            set_safe(node, function.safe(node.nodes[:arguments]))
          else
            set_safe(node, [])
          end
        elsif node.is_a?(Node::Expression::GetAttribute) && node.nodes[:node].is_a?(Node::Expression::Variable::Context)
          name = node.nodes[:node].attributes[:name]

          if safe_vars.include?(name)
            set_safe(node, [:all])
          end
        end

        node
      end

      # @param [Node::Base] node
      def safe(node)
        hash = node.object_id

        unless data.key?(hash)
          return []
        end

        data[hash].each do |bucket|
          next unless bucket[:key] == node

          if bucket[:value].include?(:html_attr)
            bucket[:value] << :html
          end

          return bucket[:value]
        end

        []
      end

      # @param [Array<String>] safe_vars
      def safe_vars=(safe_vars)
        @safe_vars = safe_vars.dup
      end

      private

      # @return [Hash{Integer => Array}]
      attr_reader :data

      # @return [Array<String>]
      attr_reader :safe_vars

      # @param [Node::Base] node
      # @param [Array] safe
      def set_safe(node, safe)
        hash = node.object_id
        found = data.fetch(hash, []).detect { |bucket| bucket[:key] == node }

        if found
          found[:value] = safe

          return
        end

        @data[hash] ||= []
        @data[hash] << {
          key: node,
          value: safe,
        }
      end

      # @param [Array<String>] a
      # @param [Array<String>] b
      def intersect_safe(a, b)
        return [] if a.empty? || b.empty?
        return b if a.include?(:all)
        return a if b.include?(:all)

        a & b
      end
    end
  end
end
