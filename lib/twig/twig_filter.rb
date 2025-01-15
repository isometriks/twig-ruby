# frozen_string_literal: true

module Twig
  class TwigFilter < Callable
    def initialize(name, callable = nil, options = {})
      super
      
      @options = {
        is_safe: nil,
        is_safe_callback: nil,
        pre_escape: nil,
        preserves_safety: nil,
        node_class: Node::Expression::Filter,
      }.merge(@options)
    end

    def node_class
      @options[:node_class]
    end
  end
end
