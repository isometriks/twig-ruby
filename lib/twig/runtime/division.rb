# frozen_string_literal: true

module Twig
  module Runtime
    # The / and // operators, which divide the way PHP does instead of
    # truncating like Ruby's Integer#/
    module Division
      # Operands are cast to numbers as PHP casts them (see
      # Arithmetic.number), so "10" / 4 is 2.5 and null / 2 is 0. An exact
      # division of two integers stays an Integer and any other division is
      # a Float, so 8 / 2 is 4 and 7 / 2 is 3.5. Dividing by zero raises
      # PHP's "Division by zero", for floats too. A BigDecimal or a Rational,
      # which PHP doesn't have, divides as Ruby does and keeps its precision,
      # and so do operands that are none of these, such as an object that
      # defines /.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Object]
      def self.divide(left, right)
        unless Arithmetic.castable?(left) && Arithmetic.castable?(right)
          return left / right
        end

        dividend = Arithmetic.number(left, left, right, '/')
        divisor = Arithmetic.number(right, left, right, '/')
        raise ZeroDivisionError, 'Division by zero' if divisor.zero?
        return dividend / divisor unless php_number?(dividend) && php_number?(divisor)

        if dividend.is_a?(Integer) && divisor.is_a?(Integer) && (dividend % divisor).zero?
          quotient = dividend / divisor
          return quotient if quotient.between?(Arithmetic::INT_MIN, Arithmetic::INT_MAX)
        end

        dividend.fdiv(divisor)
      end

      # Twig compiles a // b to PHP's (int) floor(a / b), so the quotient is
      # floored as a float and then cast to an integer, which wraps around
      # when PHP can't hold it
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Object]
      def self.floor_divide(left, right)
        quotient = divide(left, right)
        return quotient.floor.to_i unless quotient.is_a?(Integer) || quotient.is_a?(Float)

        quotient = quotient.to_f
        quotient.finite? ? Arithmetic.wrap(quotient.floor) : 0
      end

      def self.php_number?(number)
        number.is_a?(Integer) || number.is_a?(Float)
      end

      private_class_method :php_number?
    end
  end
end
