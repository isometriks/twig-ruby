# frozen_string_literal: true

module Twig
  module NodeVisitor
    class SafeAnalysis < Base
      SAFE_ALL = [
        Node::Expression::Constant,
        Node::Expression::BlockReference,
        Node::Expression::Parent,
        Node::Expression::MacroReference,
      ].freeze

      def initialize
        super

        reset
      end

      # Forgets every analyzed node. The analysis is shared by every template
      # compiled by an environment, so it must not hold on to their nodes.
      def reset
        @data = {}.compare_by_identity
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
            if (safe = filter.safe(node.nodes[:arguments])).empty?
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
        safe = data.fetch(node, []).dup

        if safe.include?(:html_attr)
          safe << :html
          safe << :html_attr_relaxed
        end

        if safe.include?(:html_attr_relaxed)
          safe << :html
        end

        safe
      end

      # @param [Array<String>] safe_vars
      def safe_vars=(safe_vars)
        @safe_vars = safe_vars.dup
      end

      private

      # @return [Hash{Node::Base => Array}]
      attr_reader :data

      # @return [Array<String>]
      attr_reader :safe_vars

      # @param [Node::Base] node
      # @param [Array] safe
      def set_safe(node, safe)
        data[node] = safe
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
