# frozen_string_literal: true

module Twig
  class Callable
    attr_reader :callable
    attr_accessor :name, :dynamic_name, :arguments

    # @param [String] name
    # @param [Proc|Nil] callable
    # @param [Hash] options
    # @option options [Hash{Symbol => String}] :argument_names the Twig name of
    #   each Ruby parameter whose name templates can't use as it is, like the
    #   argument and of join, whose Ruby parameter is and_glue as and is a
    #   Ruby keyword. The Ruby name keeps working in templates.
    def initialize(name, callable = nil, options = {})
      @name = @dynamic_name = name
      @arguments = []
      @callable = callable
      @options = {
        needs_environment: false,
        needs_context: false,
        needs_charset: false,
        is_variadic: false,
        deprecation_info: nil,
        argument_names: {},
      }.merge(options)

      deprecation_info = @options[:deprecation_info]
      return if deprecation_info.nil?

      unless deprecation_info.is_a?(DeprecatedCallableInfo)
        raise Error::Logic, "The \"deprecation_info\" option must be an instance of \"#{DeprecatedCallableInfo.name}\"."
      end

      deprecation_info.name = name
      deprecation_info.type = type
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

    # @param [Symbol] parameter a parameter of the Ruby callable
    # @return [String] the name templates give the argument
    def argument_name(parameter)
      @options[:argument_names].fetch(parameter, parameter).to_s
    end

    # @return [Hash{Symbol => String}]
    def argument_names
      @options[:argument_names]
    end

    def deprecated?
      !@options[:deprecation_info].nil?
    end

    # @param [String, nil] file
    # @param [Integer, nil] line
    def trigger_deprecation(file = nil, line = nil)
      @options[:deprecation_info].trigger_deprecation(file, line)
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
