# frozen_string_literal: true

module Twig
  # @!attribute [r] extensions
  #   @return [Hash<String, Extension::Base>]
  class ExtensionSet
    attr_reader :extensions

    def initialize
      @extensions = {}
      @extensions.default_proc = lambda { |_hash, key|
        raise "Extension '#{key}' does not exist"
      }
      @undefined_callbacks = { filter: [], function: [], test: [], token_parser: [] }
    end

    # @param [Extension::Base] extension
    def add(extension)
      raise "Extension #{extension.class} already added" if has?(extension)

      @extensions[key(extension)] = extension
      @last_modified = nil
    end

    # @param [Object, String] extension
    # @return [Boolean]
    def has?(extension)
      extensions.key?(key(extension))
    end

    # Whether the extensions' filters, functions, tests, token parsers, node
    # visitors or expression parsers have been read, as a template's
    # compilation does, or a template has been loaded, as in Twig
    def initialized?
      @runtime_initialized ||
        [@expression_parsers, @filters, @functions, @tests, @token_parsers, @node_visitors].any?
    end

    # Called each time the environment loads a template, compiled or cached,
    # like Twig's initRuntime
    def init_runtime!
      @runtime_initialized = true
    end

    # @return [Extension::Base]
    def get(extension)
      extensions[key(extension)]
    end

    def expression_parsers
      @expression_parsers ||= ExpressionParser::ExpressionParsers.new.tap do |parsers|
        extensions.each_value do |extension|
          parsers.add(extension.expression_parsers)
        end
      end
    end

    # @return [Hash{String => TwigFilter}]
    def filters
      @filters ||= extensions.
        values.
        map(&:filters).
        flatten.
        to_h { |filter| [filter.name, filter] }
    end

    # @return [Hash{String => TwigFunction}]
    def functions
      @functions ||= extensions.
        values.
        map(&:functions).
        flatten.
        to_h { |function| [function.name, function] }
    end

    # @return [Hash{String => TwigTest}]
    def tests
      @tests ||= extensions.
        values.
        map(&:tests).
        flatten.
        to_h { |test| [test.name, test] }
    end

    # @return [TwigFilter, nil]
    def filter(name)
      return filters[name] if filters.key?(name)

      dynamic_filters.each do |pattern, filter|
        if (match = Regexp.new(pattern).match(name))
          return filter.with_dynamic_arguments(name, filter.name, match.captures)
        end
      end

      undefined(:filter, name)
    end

    # @return [TwigFunction, nil]
    def function(name)
      return functions[name] if functions.key?(name)

      dynamic_functions.each do |pattern, function|
        if (match = Regexp.new(pattern).match(name))
          return function.with_dynamic_arguments(name, function.name, match.captures)
        end
      end

      undefined(:function, name)
    end

    # @return [TwigTest, nil]
    def test(name)
      return tests[name] if tests.key?(name)

      dynamic_tests.each do |pattern, test|
        if (match = Regexp.new(pattern).match(name))
          return test.with_dynamic_arguments(name, test.name, match.captures)
        end
      end

      undefined(:test, name)
    end

    # @return [Array<TokenParser::Base>]
    def token_parsers
      @token_parsers ||= extensions.
        values.map(&:token_parsers).reduce([], :concat).
        to_h { |token_parser| [token_parser.tag.to_sym, token_parser] }
    end

    # @return [TokenParser::Base, nil]
    def token_parser(name)
      token_parsers[name.to_sym] || undefined(:token_parser, name.to_s)
    end

    # Registers a callable asked for a filter, function, test or token parser
    # that no extension defines, tried in the order they were registered. It
    # gets the name and returns what to use for it, or false or nil to let
    # the next one answer.
    #
    # @param [Symbol] kind :filter, :function, :test or :token_parser
    # @param [#call] callable
    def register_undefined_callback(kind, callable)
      unless callable.respond_to?(:call)
        raise ArgumentError, "An undefined #{kind} callback needs a callable or a block."
      end

      @undefined_callbacks.fetch(kind) << callable
    end

    # @return [Array<NodeVisitor::Base>]
    def node_visitors
      @node_visitors ||= extensions.
        values.map(&:node_visitors).reduce([], :concat)
    end

    def globals
      @globals ||= extensions.
        values.map(&:globals).reduce({}, :merge)
    end

    # The latest time any extension's code changed, read once like PHP's
    # ExtensionSet::getLastModified
    #
    # @return [Integer]
    def last_modified
      @last_modified ||= extensions.each_value.map do |extension|
        extension.respond_to?(:last_modified) ? extension.last_modified : 0
      end.max || 0
    end

    # The extensions in the order they were added, which goes into the name of
    # every template class compiled with them
    #
    # @return [String]
    def signature
      extensions.keys.to_json
    end

    private

    def undefined(kind, name)
      @undefined_callbacks[kind].each do |callback|
        if (callable = callback.call(name))
          return callable
        end
      end

      nil
    end

    def dynamic_filters
      @dynamic_filters ||= filters.
        select { |name, _| name.include?('*') }.
        transform_keys { |name| dynamic_callable_regex(name) }
    end

    def dynamic_functions
      @dynamic_functions ||= functions.
        select { |name, _| name.include?('*') }.
        transform_keys { |name| dynamic_callable_regex(name) }
    end

    def dynamic_tests
      @dynamic_tests ||= tests.
        select { |name, _| name.include?('*') }.
        transform_keys { |name| dynamic_callable_regex(name) }
    end

    def dynamic_callable_regex(name)
      "^#{Regexp.quote(name).gsub('\\*', '(.*?)')}$"
    end

    def key(object)
      case object
      when String
        object
      when Class
        object.to_s
      else
        object.class.to_s
      end
    end
  end
end
