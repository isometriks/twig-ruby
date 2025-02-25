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

    def needs_charset?
      @options[:needs_charset]
    end

    def needs_environment?
      @options[:needs_environment]
    end

    def needs_context?
      @options[:needs_context]
    end
  end
end
