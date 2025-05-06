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

    # @param [Node::Base] filter_args
    def safe(filter_args)
      return @options[:is_safe] unless @options[:is_safe].nil?
      return @options[:is_safe_callback].call(filter_args) unless @options[:is_safe_callback].nil?

      []
    end

    def preserves_safety
      @options[:preserves_safety] || []
    end

    def pre_escape
      @options[:pre_escape]
    end

    def type
      :filter
    end

    def node_class
      @options[:node_class]
    end
  end
end
