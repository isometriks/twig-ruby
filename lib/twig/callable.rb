# frozen_string_literal: true

module Twig
  class Callable
    attr_reader :name, :dynamic_name, :callable

    # @param [String] name
    # @param [Proc|Nil] callable
    # @param [Hash] options
    def initialize(name, callable = nil, options = {})
      @name = @dynamic_name = name
      @callable = callable
      @options = {
        needs_environment: false,
        needs_context: false,
        needs_charset: false,
        is_variadic: false,
      }.merge(options)
    end
  end
end
