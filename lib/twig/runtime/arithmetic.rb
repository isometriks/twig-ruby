# frozen_string_literal: true

module Twig
  module Runtime
    # The +, -, * and bitwise operators, and the casts PHP applies to the
    # operands of every arithmetic operator, instead of Ruby's operators,
    # which concatenate strings and raise for null
    module Arithmetic
      # A PHP numeric string, or the number a leading-numeric string such as
      # "7abc" starts with
      NUMERIC_PREFIX = /\A[ \t\n\r\v\f]*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?/
      INT_MAX = (2**63) - 1
      INT_MIN = -(2**63)

      private_constant :NUMERIC_PREFIX

      # @return [Numeric] left + right in PHP
      def self.add(left, right)
        operate(left, right, '+') { |l, r| l + r }
      end

      # @return [Numeric] left - right in PHP
      def self.subtract(left, right)
        operate(left, right, '-') { |l, r| l - r }
      end

      # @return [Numeric] left * right in PHP, which is also how PHP negates
      #   a value
      def self.multiply(left, right)
        operate(left, right, '*') { |l, r| l * r }
      end

      # @return [Integer, String] left & right in PHP
      def self.bitwise_and(left, right)
        bitwise(left, right, '&')
      end

      # @return [Integer, String] left | right in PHP
      def self.bitwise_or(left, right)
        bitwise(left, right, '|')
      end

      # @return [Integer, String] left ^ right in PHP
      def self.bitwise_xor(left, right)
        bitwise(left, right, '^')
      end

      # Whether PHP casts a value to a number for arithmetic. Other values,
      # such as an object that defines the operator, use Ruby's operator.
      def self.castable?(value)
        value.is_a?(Numeric) || value.is_a?(String) || value.is_a?(Symbol) ||
          value.nil? || value == true || value == false
      end

      # Casts an operand to a number as PHP does: a numeric string, or one
      # with a leading number, is read as that number, null and false are 0,
      # and true is 1. A string that doesn't start with a number raises PHP's
      # TypeError.
      #
      # @param [Object] value
      # @param [Object] left the left operand, for the error message
      # @param [Object] right the right operand, for the error message
      # @param [String] operator
      # @return [Numeric]
      def self.number(value, left, right, operator)
        case value
        when Numeric
          value
        when String, Symbol
          number = NUMERIC_PREFIX.match(value.to_s.b)&.[](0)
          raise TypeError, "Unsupported operand types: #{type(left)} #{operator} #{type(right)}" if number.nil?

          if number.match?(/[.eE]/)
            number.strip.to_f
          else
            integer = number.strip.to_i
            integer.between?(INT_MIN, INT_MAX) ? integer : integer.to_f
          end
        else
          value ? 1 : 0
        end
      end

      # Casts an operand to an integer as PHP does for % and the bitwise
      # operators: a float is truncated, wrapping around when PHP can't hold
      # it, and a float read from a string is capped at PHP's limits
      #
      # @return [Integer]
      def self.integer(value, left, right, operator)
        number = number(value, left, right, operator)
        return number if number.is_a?(Integer)

        number = number.to_f
        return 0 unless number.finite?

        if value.is_a?(String) || value.is_a?(Symbol)
          number.to_i.clamp(INT_MIN, INT_MAX)
        else
          wrap(number.to_i)
        end
      end

      # An integer PHP can't hold as it wraps around in a cast from a float
      #
      # @param [Integer] integer
      # @return [Integer]
      def self.wrap(integer)
        integer %= 2**64
        integer > INT_MAX ? integer - (2**64) : integer
      end

      # The name PHP gives the type of a value in an error
      def self.type(value)
        case value
        when Integer then 'int'
        when Numeric then 'float'
        when String, Symbol then 'string'
        when nil then 'null'
        when true, false then 'bool'
        when Array, Hash then 'array'
        else value.class.name
        end
      end

      # An integer result PHP can't hold becomes a float, as PHP computes it
      # with floats instead
      def self.operate(left, right, operator)
        return left.public_send(operator, right) unless castable?(left) && castable?(right)

        left_number = number(left, left, right, operator)
        right_number = number(right, left, right, operator)
        result = yield(left_number, right_number)
        return result unless result.is_a?(Integer) && !result.between?(INT_MIN, INT_MAX)

        yield(left_number.to_f, right_number.to_f)
      end

      # Two strings combine byte by byte, as in PHP, and anything else is
      # cast to integers first
      def self.bitwise(left, right, operator)
        return left.public_send(operator, right) unless castable?(left) && castable?(right)

        if (left.is_a?(String) || left.is_a?(Symbol)) && (right.is_a?(String) || right.is_a?(Symbol))
          return bitwise_strings(left.to_s.b, right.to_s.b, operator).force_encoding(left.to_s.encoding)
        end

        integer(left, left, right, operator).public_send(operator, integer(right, left, right, operator))
      end

      # & and ^ keep the length of the shorter string and | the longer one's
      def self.bitwise_strings(left, right, operator)
        length = operator == '|' ? [left.bytesize, right.bytesize].max : [left.bytesize, right.bytesize].min
        left_bytes = left.bytes
        right_bytes = right.bytes

        Array.new(length) do |index|
          left_byte = left_bytes[index]
          right_byte = right_bytes[index]
          next left_byte || right_byte if left_byte.nil? || right_byte.nil?

          left_byte.public_send(operator, right_byte)
        end.pack('C*')
      end

      private_class_method :operate, :bitwise, :bitwise_strings
    end
  end
end
