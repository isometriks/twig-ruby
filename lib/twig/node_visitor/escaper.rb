# frozen_string_literal: true

module Twig
  module NodeVisitor
    class Escaper < Base
      attr_reader :escaping_strategy

      def initialize
        super

        @default_strategy = false
        @status_stack = []
        @blocks = {}
        @safe_vars = []
        @safe_analysis = SafeAnalysis.new
      end

      def enter_node(node, env)
        case node
        when Node::Module
          if env.extension?(Extension::Escaper.name)
            default_strategy = env.extension(Extension::Escaper.name).default_strategy(node.template_name)
            @default_strategy = default_strategy if default_strategy
          end

          @blocks = {}
          @safe_vars = []
        when Node::AutoEscape
          @status_stack << node.attributes[:value].then { |v| v.is_a?(String) ? v.to_sym : v }
        when Node::Block
          @status_stack << blocks.fetch(node.attributes[:name], need_escaping)
        when Node::Import
          @safe_vars << node.nodes[:var].nodes[:var].attributes[:name]
        end

        node
      end

      def leave_node(node, env)
        if node.is_a?(Node::Module)
          @default_strategy = false
          @safe_vars = []
          @blocks = {}
        elsif node.is_a?(Node::Expression::Filter)
          return pre_escape_filter_node(node, env)
        elsif node.is_a?(Node::Print) && (type = need_escaping) != false
          expression = node.nodes[:expr]

          # @todo Operator Escape Interface
          node.nodes[:expr] = escape_expression(expression, env, type)

          return node
        end

        if node.is_a?(Node::AutoEscape) || node.is_a?(Node::Block)
          @status_stack.pop
        elsif node.is_a?(Node::BlockReference)
          @blocks[node.attributes[:name]] = need_escaping
        end

        node
      end

      private

      # @return [SafeAnalysis]
      attr_reader :safe_analysis

      # @return [String, Boolean]
      attr_reader :default_strategy

      # @return [Hash{String => String, Boolean}]
      attr_reader :blocks

      # @return [Array]
      attr_reader :status_stack

      # @return [String, Boolean]
      def need_escaping
        unless status_stack.empty?
          return status_stack.last
        end

        default_strategy || false
      end

      # @param [Node::Expression::Base] expression
      # @param [Environment] env
      # @param [Symbol] type
      def escape_expression(expression, env, type)
        safe_for?(type, expression, env) ? expression : get_escaper_filter(env, type, expression)
      end

      # @param [Node::Exression::Filter] filter
      # @param [Environment] env
      # @return [Node::Expression::Filter]
      def pre_escape_filter_node(filter, env)
        if (type = filter.attributes[:twig_callable].pre_escape).nil?
          return filter
        end

        node = filter.nodes[:node]

        if safe_for?(type, node, env)
          return filter
        end

        filter.nodes[:node] = get_escaper_filter(env, type, node)

        filter
      end

      # @param [Environment] env
      # @param [Symbol] type
      # @param [Node::Expression::Base] node
      # @return [Node::Expression::Filter]
      def get_escaper_filter(env, type, node)
        line = node.lineno
        filter = env.filter('escape')
        args = Node::Nodes.new(
          AutoHash.new.add(
            Node::Expression::Constant.new(type, line),
            Node::Expression::Constant.new(nil, line),
            Node::Expression::Constant.new(true, line)
          )
        )

        Node::Expression::Filter.new(node, filter, args, line)
      end

      def safe_for?(type, expression, env)
        safe = safe_analysis.safe(expression)

        if safe.empty?
          @traverser ||= NodeTraverser.new(env, [safe_analysis])

          safe_analysis.safe_vars = @safe_vars
          @traverser.traverse(expression)

          safe = safe_analysis.safe(expression)
        end

        safe.include?(type) || safe.include?(:all)
      end
    end
  end
end
