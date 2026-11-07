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
