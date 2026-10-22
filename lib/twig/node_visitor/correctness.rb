# frozen_string_literal: true

module Twig
  module NodeVisitor
    # Checks that the structure of a template is valid, for instance that a
    # template extending another one only has content inside blocks.
    class Correctness < Base
      def initialize
        super
        reset_state
      end

      def enter_node(node, env)
        if node.is_a?(Node::Module)
          enter_module(node)

          return node
        end

        enter_scope(node)

        if node.is_a?(Node::BlockReference)
          check_block_definition_nesting(node)
        end

        node
      end

      def leave_node(node, env)
        if node.is_a?(Node::Module)
          reset_state

          return node
        end

        leave_scope(node)

        node
      end

      def priority
        -255
      end

      private

      # @param [Node::Module] node
      def enter_module(node)
        reset_state
        @has_parent = node.nodes.key?(:parent)

        root_nodes(node).each do |n|
          if @has_parent && !empty_output_node?(n)
            raise Error::Syntax.new(
              'A template that extends another one cannot include content outside Twig blocks. Did you forget ' \
              'to put the content inside a {% block %} tag?',
              n.lineno,
              n.source_context
            )
          end

          @root_nodes[n] = true
        end
      end

      def reset_state
        @root_nodes = {}.compare_by_identity
        # Stack of the output-wrapping tags ("if", "for", "set", ...) currently open;
        # the last one is the nearest tag a "block" definition would be nested under.
        @tag_stack = []
        @has_parent = false
        @block_depth = 0
        @macro_depth = 0
        @capturing_depth = 0
      end

      # @param [Node::Module] node
      # @return [Array<Node::Base>]
      def root_nodes(node)
        body = node.nodes[:body].nodes[0]

        # Parser#subparse does not wrap the parsed nodes when there is only one,
        # so body can be a single "real" node instead of a Nodes container; in that
        # case it is the only root node and must not be iterated over its children.
        if body.is_a?(Node::Nodes) || body.instance_of?(Node::Base)
          body.nodes.values
        else
          [body]
        end
      end

      def enter_scope(node)
        @capturing_depth += 1 if node.is_a?(Node::Capturing)

        if node.is_a?(Node::Block)
          @block_depth += 1
        elsif node.is_a?(Node::Macro)
          @macro_depth += 1
        elsif node.tag && !node.is_a?(Node::BlockReference)
          @tag_stack << node
        end
      end

      def leave_scope(node)
        @capturing_depth -= 1 if node.is_a?(Node::Capturing)

        if node.is_a?(Node::Block)
          @block_depth -= 1
        elsif node.is_a?(Node::Macro)
          @macro_depth -= 1
        elsif node.tag && !node.is_a?(Node::BlockReference)
          @tag_stack.pop
        end
      end

      # A "block" definition nested under an output-wrapping tag is registered globally
      # regardless of that tag, so the nesting is misleading. This only matters at the root
      # of a child template's body: once inside a block, a macro, an output capture, or in
      # a standalone template, the block is rendered in place and behaves like any other.
      #
      # @param [Node::BlockReference] node
      def check_block_definition_nesting(node)
        if !@has_parent || @block_depth.positive? || @macro_depth.positive? ||
           @capturing_depth.positive? || @tag_stack.empty?
          return
        end

        tag = @tag_stack.last

        raise Error::Syntax.new(
          "A \"block\" tag cannot be under a \"#{tag.tag}\" tag (line #{tag.lineno}).",
          node.lineno,
          node.source_context
        )
      end

      # Returns true if the node never outputs anything or if the output is empty.
      #
      # @param [Node::Base] node
      def empty_output_node?(node)
        # a "block" tag in such a node will serve as a block definition AND be displayed in place as well
        return true if node.is_a?(Node::Capturing)

        # Can the text be considered "empty" (only whitespace)?
        return node.blank? if node.is_a?(Node::Text)

        if !node.is_a?(Node::BlockReference) && node.is_a?(Node::Output)
          return false
        end

        node.nodes.each_value.all? { |n| empty_output_node?(n) }
      end
    end
  end
end
