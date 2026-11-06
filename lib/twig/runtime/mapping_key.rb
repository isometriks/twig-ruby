# frozen_string_literal: true

module Twig
  module Runtime
    # Coerces a dynamic mapping key, as in `{(expr): value}`, the way PHP
    # casts one to an array offset. PHP keeps this logic in ArrayExpression
    # (a string cast); it lives here so the compiled template stays short.
    module MappingKey
      # Integers, strings and symbols (the Ruby form of a name key) are kept,
      # nil becomes '', booleans become 1 and '' as in PHP, and anything else
      # is converted with to_s
      #
      # @param [Object] value
      # @return [Integer, String, Symbol]
      def self.coerce(value)
        case value
        when Integer, String, Symbol
          value
        when nil, false
          ''
        when true
          1
        else
          value.to_s
        end
      end

      # Whether PHP stores the key as an integer: an Integer, or a String
      # holding a decimal integer such as "5", which PHP turns into 5
      #
      # @param [Object] key
      # @return [Boolean]
      def self.integer?(key)
        key.is_a?(Integer) || (key.is_a?(String) && key.match?(/\A(?:0|-?[1-9]\d*)\z/))
      end
    end
  end
end
