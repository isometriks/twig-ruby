module Twig
  class Filter < Callable
    def initialize(name, callable = nil, options = {})
      super
      
      @options = {
        is_safe: nil,
        is_safe_callback: nil,
        pre_escape: nil,
        preserves_safety: nil,
        node_class: Node::Expression::FilterExpression,
      }.merge(@options)
    end

    def node_class
      @options[:node_class]
    end
  end
end
