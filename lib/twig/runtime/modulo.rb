# frozen_string_literal: true

module Twig
  module Runtime
    # The % operator, which takes the remainder the way PHP does instead of
    # flooring like Ruby's Integer#%
    module Modulo
      # A PHP numeric string, or the number a leading-numeric string such as
      # "7abc" starts with
      NUMERIC_PREFIX = /\A[ \t\n\r\v\f]*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?/

      private_constant :NUMERIC_PREFIX

      # Both operands are cast to integers as PHP casts them, so floats are
      # truncated, numeric strings are read as numbers, true is 1 and false
      # and null are 0. The remainder takes the sign of the dividend, so
      # -7 % 2 is -1, 7 % -2 is 1, 5.5 % 2 is 1 and "7" % 2 is 1. A string
      # that is not numeric raises, as in PHP. Operands that are none of these,
      # such as an object that defines %, use Ruby's %.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Object]
      def self.modulo(left, right)
        return left % right unless castable?(left) && castable?(right)

        dividend = to_integer(left, left, right)
        divisor = to_integer(right, left, right)
        raise ZeroDivisionError, 'Modulo by zero' if divisor.zero?

        dividend.remainder(divisor)
      end

      def self.castable?(value)
        value.is_a?(Numeric) || value.is_a?(String) || value.nil? || value == true || value == false
      end

      def self.to_integer(value, left, right)
        case value
        when Integer
          value
        when Float
          value.finite? ? value.to_i : 0
        when Numeric
          value.to_i
        when String
          number = NUMERIC_PREFIX.match(value)&.[](0)
          raise TypeError, "Unsupported operand types: #{type(left)} % #{type(right)}" if number.nil?

          number.match?(/[.eE]/) ? number.to_f.to_i : number.to_i
        else
          value ? 1 : 0
        end
      end

      # The name PHP gives the type of a value in an error
      def self.type(value)
        case value
        when Integer then 'int'
        when Numeric then 'float'
        when String then 'string'
        when nil then 'null'
        else 'bool'
        end
      end

      private_class_method :castable?, :to_integer, :type
    end
  end
end
