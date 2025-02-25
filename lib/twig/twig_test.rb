# frozen_string_literal: true

module Twig
  class TwigTest < Callable
    def initialize(name, callable = nil, options = {})
      super

      @options = {
        node_class: Node::Expression::Test::Base,
        one_mandatory_argument: false,
      }.merge(@options)
    end

    def type
      :test
    end

    def node_class
      @options[:node_class]
    end

    # @return [Boolean]
    def one_mandatory_argument?
      @options[:one_mandatory_argument]
    end

    def needs_context?
      false
    end
  end
end
