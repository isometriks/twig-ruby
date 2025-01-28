# frozen_string_literal: true

module Twig
  class TwigFunction < Callable
    def initialize(name, callable = nil, options = {})
      super

      @options = {
        is_safe: nil,
        is_safe_callback: nil,
        node_class: Node::Expression::Function,
        parser_callable: nil,
      }.merge(@options)
    end

    def type
      :function
    end

    # @return [Proc|nil]
    def parser_callable
      @options[:parser_callable]
    end

    def node_class
      @options[:node_class]
    end
  end
end
