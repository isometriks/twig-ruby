# frozen_string_literal: true

module Twig
  module Util
    # Converts a value the way PHP casts it to a string, an int or a float,
    # where Ruby's to_s, to_i and to_f give other results: true is "1" and
    # 1, null and false are "" and 0, a float is printed as PHP prints it,
    # and a string is read for the number at its start, so "12abc" is 12.
    module PhpCast
      LONG_MIN = -2**63
      LONG_MAX = (2**63) - 1
      LONG_RANGE = 2**64
      NUMERIC_PREFIX = /\A[ \t\n\r\v\f]*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)/

      module_function

      # @return [String]
      def to_string(value)
        case value
        when nil, false then ''
        when true then '1'
        when Float then PhpSprintf.float_to_string(value)
        when Array, Hash then 'Array'
        else value.to_s
        end
      end

      # @return [Integer]
      def to_int(value)
        case value
        when nil, false then 0
        when Integer then wrap(value)
        when Numeric then float_to_int(value.to_f)
        when String, Symbol then string_to_int(value.to_s)
        when Array, Hash then value.empty? ? 0 : 1
        # true, or an object
        else 1
        end
      end

      # @return [Float]
      def to_float(value)
        case value
        when nil, false then 0.0
        when Numeric then value.to_f
        when String, Symbol then value.to_s.match(NUMERIC_PREFIX)&.[](1).to_f
        when Array, Hash then value.empty? ? 0.0 : 1.0
        # true, or an object
        else 1.0
        end
      end

      # A value passed to a string parameter of a PHP function, which takes
      # anything but an array
      #
      # @param [String] parameter What PHP's TypeError names, such as
      #   "explode(): Argument #2 ($string)"
      # @return [String]
      def string_param(value, parameter)
        return to_string(value) unless value.is_a?(Hash) || value.is_a?(Array)

        raise ArgumentError, "#{parameter} must be of type string, array given"
      end

      # A value passed to an int parameter of a PHP function: a float is
      # truncated, and a string must be numeric
      #
      # @param [String] parameter What PHP's TypeError names
      # @param [String] type The type PHP's TypeError names, such as "?int"
      # @return [Integer]
      def int_param(value, parameter, type = 'int')
        number = case value
                 when true, false then value ? 1 : 0
                 when String then numeric(value)
                 when Numeric then value
                 end
        number = number.to_f if number.is_a?(Numeric) && !number.is_a?(Integer)

        if number.nil? || (number.is_a?(Float) && !(number.finite? && number.abs < 2**63))
          given = value.is_a?(Hash) || value.is_a?(Array) ? 'array' : Extension::Core.php_type(value)

          raise ArgumentError, "#{parameter} must be of type #{type}, #{given} given"
        end

        number.to_i
      end

      # The number a numeric string is, with whitespace around it allowed,
      # or nil for a string that isn't numeric
      #
      # @return [Integer, Float, nil]
      def numeric(string)
        number = string.match(/\A[ \t\n\r\v\f]*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)[ \t\n\r\v\f]*\z/)&.[](1)
        return unless number

        number.match?(/\A[+-]?\d+\z/) ? number.to_i : number.to_f
      end

      # An integer as a 64-bit one
      def wrap(integer)
        ((integer - LONG_MIN) % LONG_RANGE) + LONG_MIN
      end

      # zend_dval_to_lval: 0 for NaN and infinity, and modular arithmetic for
      # a float out of range
      def float_to_int(float)
        float.finite? ? wrap(float.to_i) : 0
      end

      # A numeric string out of range is capped instead
      def string_to_int(string)
        number = string.match(NUMERIC_PREFIX)&.[](1)
        return 0 unless number

        number = number.match?(/\A[+-]?\d+\z/) ? number.to_i : number.to_f
        return 0 if number.is_a?(Float) && number.nan?

        number.clamp(LONG_MIN, LONG_MAX).to_i
      end
    end
  end
end
