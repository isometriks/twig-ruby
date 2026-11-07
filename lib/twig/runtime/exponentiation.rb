# frozen_string_literal: true

module Twig
  module Runtime
    # The ** operator, which raises numbers to a power the way PHP does instead
    # of giving Ruby's Rational or Complex results
    module Exponentiation
      # Operands are cast to numbers as PHP casts them (see
      # Arithmetic.number), so "2" ** 3 is 8 and null ** 2 is 0. An integer
      # raised to a negative integer is a Float, so 2 ** -1 is 0.5, an
      # integer power PHP can't hold is a Float too, and a power with no real
      # result is NaN, as (-8) ** 0.5 is in PHP. Other operands raise to a
      # power as Ruby does.
      #
      # @param [Object] base
      # @param [Object] exponent
      # @return [Object]
      def self.power(base, exponent)
        if Arithmetic.castable?(base) && Arithmetic.castable?(exponent)
          original_base = base
          base = Arithmetic.number(original_base, original_base, exponent, '**')
          exponent = Arithmetic.number(exponent, original_base, exponent, '**')
        end

        if base.is_a?(Integer) && exponent.is_a?(Integer)
          return base.to_f**exponent if exponent.negative? || (exponent > 63 && base.abs > 1)

          result = base**exponent
          return result.between?(Arithmetic::INT_MIN, Arithmetic::INT_MAX) ? result : base.to_f**exponent
        end

        result = base**exponent

        if result.is_a?(Complex) && !base.is_a?(Complex) && !exponent.is_a?(Complex)
          Float::NAN
        else
          result
        end
      end
    end
  end
end
