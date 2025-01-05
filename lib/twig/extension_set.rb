module Twig
  # @!attribute [r] extensions
  #   @return [Hash<String, Extension::Extension>]
  class ExtensionSet
    attr_reader :extensions

    def initialize
      @extensions = {}
    end

    # @param [Extension::Extension] extension
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

    def get_operators
      all_unary, all_binary = {}, {}

      extensions.values.map(&:operators).each do |unary, binary|
        all_unary.merge!(unary)
        all_binary.merge!(binary)
      end

      [all_unary, all_binary]
    end
  end
end
