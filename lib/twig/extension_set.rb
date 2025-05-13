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
    end

    # @param [Extension::Base] extension
    def add(extension)
      raise "Extension #{extension.class} already added" if has?(extension)

      @extensions[key(extension)] = extension
    end

    # @param [Object, String] extension
    # @return [Boolean]
    def has?(extension)
      extensions.key?(key(extension))
    end

    # @return [Extension::Base]
    def get(extension)
      extensions[key(extension)]
    end

    def operators
      all_unary = {}
      all_binary = {}

      extensions.values.map(&:operators).each do |unary, binary|
        all_unary.merge!(unary)
        all_binary.merge!(binary)
      end

      [all_unary, all_binary]
    end

    def filters
      @filters ||= extensions.
        values.
        map(&:filters).
        flatten.
        to_h { |filter| [filter.name.to_sym, filter] }
    end

    def functions
      @functions ||= extensions.
        values.
        map(&:functions).
        flatten.
        to_h { |function| [function.name.to_sym, function] }
    end

    def tests
      @tests ||= extensions.
        values.
        map(&:tests).
        flatten.
        to_h { |test| [test.name.to_sym, test] }
    end

    def filter(name)
      filters[name.to_sym]
    end

    def function(name)
      functions[name.to_sym]
    end

    def test(name)
      tests[name.to_sym]
    end

    # @return [Array<TokenParser::Base>]
    def token_parsers
      @token_parsers ||= extensions.
        values.map(&:token_parsers).reduce([], :concat).
        to_h { |token_parser| [token_parser.tag.to_sym, token_parser] }
    end

    # @return [TokenParser::Base, nil]
    def token_parser(name)
      token_parsers[name.to_sym]
    end

    # @return [Array<NodeVisitor::Base>]
    def node_visitors
      @node_visitors ||= extensions.
        values.map(&:node_visitors).reduce([], :concat)
    end

    private

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
