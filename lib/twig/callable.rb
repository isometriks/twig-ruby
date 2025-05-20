# frozen_string_literal: true

module Twig
  class Callable
    attr_reader :callable
    attr_accessor :name, :dynamic_name, :arguments

    # @param [String] name
    # @param [Proc|Nil] callable
    # @param [Hash] options
    def initialize(name, callable = nil, options = {})
      @name = @dynamic_name = name
      @arguments = []
      @callable = callable
      @options = {
        needs_environment: false,
        needs_context: false,
        needs_charset: false,
        is_variadic: false,
      }.merge(options)
    end

    def type
      raise NotImplementedError
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

    def with_dynamic_arguments(name, dynamic_name, arguments)
      new = clone
      new.name = name
      new.dynamic_name = dynamic_name
      new.arguments = arguments

      new
    end
  end
end
