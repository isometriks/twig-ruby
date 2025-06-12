# frozen_string_literal: true

module Twig
  module Extension
    class Escaper < Base
      def initialize(default_strategy = :html)
        super()

        @default_strategy = default_strategy
      end

      def filters
        [
          TwigFilter.new('escape', runtime(Runtime::Escaper, :escape), {
            is_safe_callback: static(:escape_filter_is_safe),
          }),
          TwigFilter.new('e', runtime(Runtime::Escaper, :escape), {
            is_safe_callback: static(:escape_filter_is_safe),
          }),
          TwigFilter.new('raw', nil, {
            is_safe: [:all], node_class: Node::Expression::Filter::Raw
          }),
        ]
      end

      def token_parsers
        [
          TokenParser::AutoEscape.new,
        ]
      end

      def node_visitors
        [
          NodeVisitor::Escaper.new,
        ]
      end

      def default_strategy(name)
        :html
      end

      # @param [Node::Base] filter_args
      def self.escape_filter_is_safe(filter_args)
        filter_args.nodes.each_value do |arg|
          if arg.is_a?(Node::Expression::Constant)
            return [arg.attributes[:value]]
          end
        end

        [:html]
      end
    end
  end
end
