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
      raise "Extension #{extension.class.name} already added" if has?(extension)

      @extensions[extension.class.name] = extension
    end

    # @param [Object, String] extension
    # @return [Boolean]
    def has?(extension)
      extension = extension.class.name unless extension.is_a?(String)
      extensions.key?(extension.to_s)
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

    def helper_methods
      @helper_methods ||= extensions.
        values.
        map(&:helper_methods).
        reduce([], :concat).
        map(&:to_sym)
    end

    def filters
      @filters ||= extensions.
        values.
        map(&:filters).
        flatten.
        to_h { |filter| [filter.name.to_sym, filter] }
    end

    def filter(name)
      filters[name.to_sym]
    end

    def token_parsers
      @token_parsers ||= extensions.
        values.map(&:token_parsers).reduce([], :concat).
        to_h { |token_parser| [token_parser.tag.to_sym, token_parser] }
    end

    # @return [TokenParser::Base|nil]
    def token_parser(name)
      token_parsers[name.to_sym]
    end
  end
end
