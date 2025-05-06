# frozen_string_literal: true

module Twig
  class NodeTraverser
    def initialize(env, visitors = [])
      @env = env
      @visitors = {}

      visitors.each { |visitor| add_visitor(visitor) }
    end

    # @param [NodeVisitor::Base]
    def add_visitor(visitor)
      @visitors[visitor.priority] ||= []
      @visitors[visitor.priority] << visitor
    end

    # Traverses a node and calls the registered visitors.
    # @param [Node::Base] node
    def traverse(node)
      @visitors = @visitors.sort.to_h

      @visitors.each_value do |visitors|
        visitors.each do |visitor|
          node = traverse_for_visitor(visitor, node)
        end
      end

      node
    end

    private

    # @param [NodeVisitor::Base] visitor
    # @param [Node::Base] node
    def traverse_for_visitor(visitor, node)
      node = visitor.enter_node(node, @env)

      node.nodes.each do |k, n|
        if (m = traverse_for_visitor(visitor, n)).nil?
          node.nodes.delete(k)
        elsif m != n
          node.nodes[k] = m
        end
      end

      visitor.leave_node(node, @env)
    end
  end
end
