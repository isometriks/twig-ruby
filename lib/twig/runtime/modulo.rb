# frozen_string_literal: true

module Twig
  module Runtime
    # The % operator, which takes the remainder the way PHP does instead of
    # flooring like Ruby's Integer#%
    module Modulo
      # Both operands are cast to integers as PHP casts them (see
      # Arithmetic.integer), so floats are truncated, numeric strings are
      # read as numbers, true is 1 and false and null are 0. The remainder
      # takes the sign of the dividend, so -7 % 2 is -1, 7 % -2 is 1, 5.5 % 2
      # is 1 and "7" % 2 is 1. A string that is not numeric raises, as in
      # PHP. Operands that are none of these, such as an object that defines
      # %, use Ruby's %.
      #
      # @param [Object] left
      # @param [Object] right
      # @return [Object]
      def self.modulo(left, right)
        return left % right unless Arithmetic.castable?(left) && Arithmetic.castable?(right)

        dividend = Arithmetic.integer(left, left, right, '%')
        divisor = Arithmetic.integer(right, left, right, '%')
        raise ZeroDivisionError, 'Modulo by zero' if divisor.zero?

        dividend.remainder(divisor)
      end
    end
  end
end
